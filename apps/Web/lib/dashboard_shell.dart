import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Shared shell: orange top nav, optional portal sidebar, themed page background.
class DashboardAppShell extends ConsumerWidget {
  final DashboardNavTab activeTab;
  final Widget child;
  final bool showBackOnMobile;
  final String? titleOverride;
  final Widget? sidebar;
  final bool useWideLayout;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const DashboardAppShell({
    super.key,
    required this.activeTab,
    required this.child,
    this.showBackOnMobile = false,
    this.titleOverride,
    this.sidebar,
    this.useWideLayout = false,
    this.scaffoldKey,
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
      key: scaffoldKey,
      drawer: isMobile && sidebar != null
          ? Drawer(child: SafeArea(child: sidebar!))
          : null,
      backgroundColor: palette.background,
      body: Column(
        children: [
          BoostDriveAuthenticatedTopNav(
            activeItem: _navHighlight(activeTab),
            showMenuButton: isMobile && sidebar != null,
            scaffoldKey: scaffoldKey,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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

/// Service-provider portal sidebar (My Services + BaTLorriH logistics).
class ProviderDashboardSidebar extends StatelessWidget {
  final ProviderHubTab activeTab;
  final ValueChanged<ProviderHubTab> onTabSelected;
  final VoidCallback onSettings;
  final VoidCallback? onSupport;
  final String? earningsDisplay;
  final String portalSubtitle;

  const ProviderDashboardSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.onSettings,
    this.onSupport,
    this.earningsDisplay,
    this.portalSubtitle = 'Manage services & logistics',
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        border: Border(right: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Portal',
                  style: DashboardTypography.labelLg(palette).copyWith(
                    color: palette.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(portalSubtitle, style: DashboardTypography.bodySm(palette)),
              ],
            ),
          ),
          Divider(height: 1, color: palette.outlineVariant.withValues(alpha: 0.2)),
          _ProviderNavItem(
            icon: Icons.dashboard_outlined,
            label: 'MY SERVICES',
            selected: activeTab == ProviderHubTab.services,
            onTap: () => onTabSelected(ProviderHubTab.services),
          ),
          _ProviderNavItem(
            icon: Icons.local_shipping_outlined,
            label: 'LOGISTICS (BATLORRIH)',
            selected: activeTab == ProviderHubTab.logistics,
            onTap: () => onTabSelected(ProviderHubTab.logistics),
          ),
          _ProviderNavItem(
            icon: Icons.settings_outlined,
            label: 'Profile Settings',
            selected: false,
            onTap: onSettings,
          ),
          if (onSupport != null)
            _ProviderNavItem(
              icon: Icons.support_agent_outlined,
              label: 'Support',
              selected: false,
              onTap: onSupport!,
            ),
          if (earningsDisplay != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ProviderDashboardUi.earningsSidebarCard(
                palette: palette,
                label: 'TOTAL EARNINGS',
                value: earningsDisplay!,
              ),
            ),
          ],
          const Spacer(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ProviderNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ProviderNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Material(
      color: selected ? palette.primary.withValues(alpha: 0.13) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: selected
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: palette.primary, width: 4)),
                )
              : null,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: selected ? palette.primary : palette.onSurfaceVariant, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: DashboardTypography.labelLg(palette).copyWith(
                    color: selected ? palette.primary : palette.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary sections inside [ProviderHubPage].
enum ProviderHubTab { services, logistics }

/// Seller portal sidebar wired to [DashboardPortalSidebar] (Stitch mockup).
class SellerDashboardSidebar extends StatelessWidget {
  final VoidCallback onAddListing;
  final VoidCallback onSettings;
  final DashboardPortalSection activeSection;
  final ValueChanged<DashboardPortalSection>? onSectionSelected;

  const SellerDashboardSidebar({
    super.key,
    required this.onAddListing,
    required this.onSettings,
    this.activeSection = DashboardPortalSection.dashboard,
    this.onSectionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardPortalSidebar(
      activeSection: activeSection,
      onSectionSelected: onSectionSelected,
      onListVehicle: onAddListing,
      onSettings: onSettings,
    );
  }
}

/// Placeholder panel for sidebar sections without a dedicated route yet (UI only).
class DashboardPortalPlaceholder extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const DashboardPortalPlaceholder({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardCard(
      padding: const EdgeInsets.all(48),
      elevated: true,
      child: Column(
        children: [
          Icon(icon, size: 56, color: palette.primary.withValues(alpha: 0.7)),
          const SizedBox(height: 20),
          Text(title, style: DashboardTypography.headlineMd(palette), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(message, style: DashboardTypography.bodyMd(palette), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
