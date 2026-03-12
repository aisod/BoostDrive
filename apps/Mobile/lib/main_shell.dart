import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'customer_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'marketplace_page.dart';
import 'providers.dart';

import 'provider_hub.dart';
import 'find_providers_page.dart';
import 'emergency_hub_page.dart';
import 'garage_page.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = ref.watch(activeRoleProvider);
    
    Widget body;
    List<BottomNavigationBarItem> navItems;
    
    if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
      body = _buildProviderBody();
      navItems = _buildProviderNav();
    } else if (activeRole == 'super_admin') {
      body = _buildSuperAdminBody();
      navItems = _buildSuperAdminNav();
    } else {
      body = _buildCustomerBody();
      navItems = _buildCustomerNav();
    }

    // Protection against out-of-bounds when switching roles
    if (_currentIndex >= navItems.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          backgroundColor: BoostDriveTheme.surfaceDark,
          selectedItemColor: BoostDriveTheme.primaryColor,
          unselectedItemColor: BoostDriveTheme.textDim,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: navItems,
        ),
      ),
    );
  }

  Widget _buildCustomerBody() {
    switch (_currentIndex) {
      case 0: return const CustomerDashboard();
      case 1: return const EmergencyHubPage();
      case 2: return const GaragePage();
      case 3: return const MarketplacePage();
      case 4: return const FindProvidersPage();
      case 5: return const ProfileSettingsPage();
      default: return const CustomerDashboard();
    }
  }

  List<BottomNavigationBarItem> _buildCustomerNav() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'HOME'),
      BottomNavigationBarItem(icon: Icon(Icons.sos_outlined), activeIcon: Icon(Icons.sos), label: 'SOS'),
      BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'GARAGE'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'SHOP'),
      BottomNavigationBarItem(icon: Icon(Icons.person_search_outlined), activeIcon: Icon(Icons.person_search), label: 'PROVIDERS'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'PROFILE'),
    ];
  }

  Widget _buildProviderBody() {
    switch (_currentIndex) {
      case 0: return const ProviderHub();
      case 1: return const Center(child: Text('Inventory', style: TextStyle(color: Colors.white)));
      case 2: return const Center(child: Text('Orders', style: TextStyle(color: Colors.white)));
      case 3: return const Center(child: Text('Services', style: TextStyle(color: Colors.white)));
      case 4: return const ProfileSettingsPage();
      default: return const ProviderHub();
    }
  }

  List<BottomNavigationBarItem> _buildProviderNav() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), activeIcon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Inventory'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Orders'),
      BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Services'),
      BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Account'),
    ];
  }

  Widget _buildSuperAdminBody() {
    switch (_currentIndex) {
      case 0: return const SuperAdminDashboard();
      case 1: return const Center(child: Text('Financials', style: TextStyle(color: Colors.white)));
      case 2: return const Center(child: Text('Partners', style: TextStyle(color: Colors.white)));
      case 3: return const Center(child: Text('SOS Feed', style: TextStyle(color: Colors.white)));
      case 4: return const Center(child: Text('More', style: TextStyle(color: Colors.white)));
      default: return const SuperAdminDashboard();
    }
  }

  List<BottomNavigationBarItem> _buildSuperAdminNav() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'OVERVIEW'),
      BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined), activeIcon: Icon(Icons.analytics), label: 'FINANCIALS'),
      BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'PARTNERS'),
      BottomNavigationBarItem(icon: Icon(Icons.sos_outlined), activeIcon: Icon(Icons.sos), label: 'SOS FEED'),
      BottomNavigationBarItem(icon: Icon(Icons.menu), activeIcon: Icon(Icons.menu), label: 'MORE'),
    ];
  }
}
