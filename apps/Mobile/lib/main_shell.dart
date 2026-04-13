import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'customer_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'marketplace_page.dart';
import 'providers.dart' show mobileShellRoleProvider;

import 'provider_hub.dart';
import 'find_providers_page.dart';
import 'emergency_hub_page.dart';
import 'garage_page.dart';
import 'admin_sos_hub_page.dart';
import 'admin_verifications_page.dart';
import 'admin_security_page.dart';
import 'provider_inventory_page.dart';
import 'provider_orders_page.dart';
import 'provider_services_page.dart';

/// Top-level (not on [State]) so Flutter Web hot reload does not leave a stale / undefined list.
const List<Widget> _customerShellTabs = [
  CustomerDashboard(),
  EmergencyHubPage(),
  GaragePage(),
  MarketplacePage(),
  FindProvidersPage(),
  ProfileSettingsPage(),
];

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
    final activeRole = ref.watch(mobileShellRoleProvider);
    
    final List<BottomNavigationBarItem> navItems;
    if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
      navItems = _buildProviderNav();
    } else if (activeRole == 'super_admin') {
      navItems = _buildSuperAdminNav();
    } else {
      navItems = _buildCustomerNav();
    }

    var displayIndex = _currentIndex;
    if (displayIndex >= navItems.length) {
      displayIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex >= navItems.length) {
          setState(() => _currentIndex = 0);
        }
      });
    }

    final Widget body;
    if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
      body = _buildProviderBody();
    } else if (activeRole == 'super_admin') {
      body = _buildSuperAdminBody();
    } else {
      final tabCount = _customerShellTabs.length;
      final safeIndex = tabCount <= 1 ? 0 : displayIndex.clamp(0, tabCount - 1);
      body = IndexedStack(
        index: safeIndex,
        children: _customerShellTabs,
      );
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
          currentIndex: displayIndex,
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
      case 1: return const ProviderInventoryPage();
      case 2: return const ProviderOrdersPage();
      case 3: return const ProviderServicesPage();
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
      case 1: return const AdminSosHubPage();
      case 2: return const AdminVerificationsPage();
      case 3: return const AdminSecurityPage();
      default: return const SuperAdminDashboard();
    }
  }

  List<BottomNavigationBarItem> _buildSuperAdminNav() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'HOME'),
      BottomNavigationBarItem(icon: Icon(Icons.sos_outlined), activeIcon: Icon(Icons.sos), label: 'SOS HUB'),
      BottomNavigationBarItem(icon: Icon(Icons.verified_user_outlined), activeIcon: Icon(Icons.verified_user), label: 'VERIFICATIONS'),
      BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: 'SECURITY'),
    ];
  }
}
