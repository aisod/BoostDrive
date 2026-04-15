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

    return PremiumPageLayout(
      // Disable global web background image here to avoid right-edge image artifact/overlay.
      showBackground: false,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Provider Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          tabs: [
            Tab(text: isSeller ? 'MY STORE' : 'MY SERVICES'),
            const Tab(text: 'BATLORRIH'),
          ],
        ),
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 120, // Adjust for AppBar and TabBar
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Trade-specific Dashboard
            isSeller ? const SellerDashboard() : const ServiceProDashboard(),
            
            // Tab 2: BaTLorriH Dashboard
            const BaTLorriHLogisticsDashboard(),
          ],
        ),
      ),
    );
  }
}
