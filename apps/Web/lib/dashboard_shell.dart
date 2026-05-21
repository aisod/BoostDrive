import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boost_drive_web/authenticated_top_nav.dart';

/// Which primary nav item is highlighted in the dashboard top bar.
enum DashboardNavTab {
  dashboard,
  messages,
  findProvider,
  listings,
  settings,
}

/// Shared shell: orange top nav, notifications, profile, light/dark page background.
class DashboardAppShell extends ConsumerWidget {
  final DashboardNavTab activeTab;
  final Widget child;
  final bool showBackOnMobile;
  final String? titleOverride;
  final Widget? sidebar;
  // Kept for hot-reload compatibility (no longer changes layout).
  final bool useWideLayout;

  const DashboardAppShell({
    super.key,
    required this.activeTab,
    required this.child,
    this.showBackOnMobile = false,
    this.titleOverride,
    this.sidebar,
    this.useWideLayout = false,
  });

  AuthenticatedNavHighlight? _navHighlight(DashboardNavTab tab) {
    switch (tab) {
      case DashboardNavTab.dashboard:
        return AuthenticatedNavHighlight.dashboard;
      case DashboardNavTab.messages:
        return AuthenticatedNavHighlight.messages;
      case DashboardNavTab.listings:
        return AuthenticatedNavHighlight.myListings;
      case DashboardNavTab.findProvider:
        return AuthenticatedNavHighlight.findProvider;
      case DashboardNavTab.settings:
        return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final palette = DashboardPalette.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    return Scaffold(
      backgroundColor: palette.background,
      body: Column(
        children: [
          BoostDriveAuthenticatedTopNav(
            activeItem: _navHighlight(activeTab),
            showMenuButton: isMobile,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sidebar != null && !isMobile) sidebar!,
                Expanded(
                  child: SingleChildScrollView(child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seller sidebar from mockup (desktop only).
class SellerDashboardSidebar extends StatelessWidget {
  final VoidCallback onAddListing;
  final VoidCallback onSettings;
  final String displayName;

  const SellerDashboardSidebar({
    super.key,
    required this.onAddListing,
    required this.onSettings,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(right: BorderSide(color: palette.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Seller',
                  style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: palette.body),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _SidebarLink(icon: Icons.dashboard_outlined, label: 'Dashboard', selected: true, onTap: () {}),
          _SidebarLink(icon: Icons.directions_car_outlined, label: 'Inventory', onTap: () {}),
          _SidebarLink(icon: Icons.receipt_long_outlined, label: 'Orders', onTap: () {}),
          _SidebarLink(icon: Icons.handyman_outlined, label: 'Service History', onTap: () {}),
          _SidebarLink(icon: Icons.insights_outlined, label: 'Analytics', onTap: () {}),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardPillButton(label: 'List Vehicle', icon: Icons.add_circle_outline, onPressed: onAddListing),
                const SizedBox(height: 16),
                _SidebarLink(icon: Icons.settings_outlined, label: 'Settings', onTap: onSettings),
                _SidebarLink(icon: Icons.support_agent_outlined, label: 'Support', onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarLink({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Material(
      color: selected ? palette.primaryFixed.withValues(alpha: 0.35) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? palette.primary : palette.body),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? palette.primary : palette.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
