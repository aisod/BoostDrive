import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'customer_dashboard.dart';
import 'super_admin_dashboard.dart';
import 'marketplace_page.dart';
import 'providers.dart' show mobileCustomerShellTabProvider, mobileShellRoleProvider;

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

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _providerTabIndex = 0;
  int _adminTabIndex = 0;

  void _onCustomerTabTapped(int index) {
    ref.read(mobileCustomerShellTabProvider.notifier).state = index;
  }

  void _onProviderTabTapped(int index) {
    setState(() => _providerTabIndex = index);
  }

  void _onAdminTabTapped(int index) {
    setState(() => _adminTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = ref.watch(mobileShellRoleProvider);
    final customerTabIndex = ref.watch(mobileCustomerShellTabProvider);
    
    final List<BottomNavigationBarItem> navItems;
    if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
      navItems = _buildProviderNav();
    } else if (activeRole == 'super_admin') {
      navItems = _buildSuperAdminNav();
    } else {
      navItems = _buildCustomerNav();
    }

    int displayIndex;
    void Function(int) onTabTapped;
    if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
      displayIndex = _providerTabIndex;
      onTabTapped = _onProviderTabTapped;
    } else if (activeRole == 'super_admin') {
      displayIndex = _adminTabIndex;
      onTabTapped = _onAdminTabTapped;
    } else {
      displayIndex = customerTabIndex;
      onTabTapped = _onCustomerTabTapped;
    }

    if (displayIndex >= navItems.length) {
      displayIndex = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
          if (_providerTabIndex >= navItems.length) setState(() => _providerTabIndex = 0);
        } else if (activeRole == 'super_admin') {
          if (_adminTabIndex >= navItems.length) setState(() => _adminTabIndex = 0);
        } else if (customerTabIndex >= navItems.length) {
          ref.read(mobileCustomerShellTabProvider.notifier).state = 0;
        }
      });
    }

    final Widget body;
    if (activeRole == 'service_pro' || activeRole == 'seller' || activeRole == 'logistics') {
      body = _buildProviderBody();
    } else if (activeRole == 'super_admin') {
      body = _buildSuperAdminBody();
    } else {
      final safeIndex = displayIndex.clamp(0, 5);
      // One tab at a time; unique keys avoid reusing the same const widget instance after hot reload.
      body = KeyedSubtree(
        key: ValueKey('customer_tab_$safeIndex'),
        child: _buildCustomerTab(safeIndex),
      );
    }

    final palette = DashboardPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: body,
      bottomNavigationBar: MobileCustomerUi.glassBottomNav(
        palette: palette,
        child: BottomNavigationBar(
          currentIndex: displayIndex,
          onTap: onTabTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFF6600),
          unselectedItemColor: palette.muted,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontSize: 10, letterSpacing: 0.5),
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

  Widget _buildCustomerTab(int index) {
    return switch (index) {
      0 => const CustomerDashboard(key: ValueKey('customer_home')),
      1 => const EmergencyHubPage(key: ValueKey('customer_sos')),
      2 => const GaragePage(key: ValueKey('customer_garage')),
      3 => const MarketplacePage(key: ValueKey('customer_shop')),
      4 => const FindProvidersPage(key: ValueKey('customer_providers')),
      5 => const ProfileSettingsPage(key: ValueKey('customer_profile')),
      _ => const CustomerDashboard(key: ValueKey('customer_home')),
    };
  }

  Widget _buildProviderBody() {
    final tab = _providerTabIndex.clamp(0, 4);
    return KeyedSubtree(
      key: ValueKey('provider_tab_$tab'),
      child: switch (tab) {
        0 => const ProviderHub(key: ValueKey('provider_hub')),
        1 => const ProviderInventoryPage(key: ValueKey('provider_inventory')),
        2 => const ProviderOrdersPage(key: ValueKey('provider_orders')),
        3 => const ProviderServicesPage(key: ValueKey('provider_services')),
        4 => const ProfileSettingsPage(key: ValueKey('provider_profile')),
        _ => const ProviderHub(key: ValueKey('provider_hub')),
      },
    );
  }

  List<BottomNavigationBarItem> _buildProviderNav() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.hub_outlined), activeIcon: Icon(Icons.hub), label: 'HUB'),
      BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'INVENTORY'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'ORDERS'),
      BottomNavigationBarItem(icon: Icon(Icons.handyman_outlined), activeIcon: Icon(Icons.handyman), label: 'SERVICES'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'ACCOUNT'),
    ];
  }

  Widget _buildSuperAdminBody() {
    final tab = _adminTabIndex.clamp(0, 3);
    return KeyedSubtree(
      key: ValueKey('admin_tab_$tab'),
      child: switch (tab) {
        0 => const SuperAdminDashboard(key: ValueKey('admin_home')),
        1 => const AdminSosHubPage(key: ValueKey('admin_sos')),
        2 => const AdminVerificationsPage(key: ValueKey('admin_verifications')),
        3 => const AdminSecurityPage(key: ValueKey('admin_security')),
        _ => const SuperAdminDashboard(key: ValueKey('admin_home')),
      },
    );
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
