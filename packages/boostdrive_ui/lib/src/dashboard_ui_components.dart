import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';
import 'dashboard_typography.dart';

/// Seller portal sidebar destinations (visual selection only).
enum DashboardPortalSection {
  dashboard,
  orders,
  serviceHistory,
  analytics,
  settings,
  support,
}

class DashboardPageContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const DashboardPageContainer({
    super.key,
    required this.child,
    this.maxWidth = 1440,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 900;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 32,
            vertical: isMobile ? 16 : 24,
          ),
          child: child,
        ),
      ),
    );
  }
}

class DashboardWelcomeHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const DashboardWelcomeHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: DashboardTypography.headlineLg(palette)),
        const SizedBox(height: 8),
        Text(subtitle, style: DashboardTypography.bodyMd(palette)),
      ],
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget? trailing;

  const DashboardSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      children: [
        Icon(icon, color: palette.primary, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: palette.title,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DashboardCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool elevated;

  const DashboardCard({
    super.key,
    required this.child,
    this.padding,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(palette.radiusDefault),
        border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: elevated ? palette.cardShadowHigh : palette.cardShadowLow,
      ),
      child: child,
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconTint;

  const DashboardStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconTint,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final tint = iconTint ?? palette.primary;
    return DashboardCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: palette.primaryFixed.withValues(alpha: isDarkContext(context) ? 0.35 : 1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: tint, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.body,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: palette.primary,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static bool isDarkContext(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

class DashboardPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  const DashboardPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: outlined ? palette.primary : Colors.white),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: outlined ? palette.primary : Colors.white,
          ),
        ),
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const StadiumBorder(),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primaryBright,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
      ),
      child: child,
    );
  }
}

class DashboardStatusChip extends StatelessWidget {
  final String label;

  const DashboardStatusChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: palette.primary,
        ),
      ),
    );
  }
}

/// Stitch-style page title block (headline + subtitle + optional actions).
class DashboardPageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const DashboardPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DashboardTypography.headlineLg(palette)),
              const SizedBox(height: 6),
              Text(subtitle, style: DashboardTypography.bodyMd(palette)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Seller / portal left navigation from Stitch mockups.
class DashboardPortalSidebar extends StatelessWidget {
  final String portalTitle;
  final String portalSubtitle;
  final DashboardPortalSection activeSection;
  final ValueChanged<DashboardPortalSection>? onSectionSelected;
  final VoidCallback onListVehicle;
  final VoidCallback? onSettings;
  final VoidCallback? onSupport;
  final bool showSellerSections;

  const DashboardPortalSidebar({
    super.key,
    this.portalTitle = 'Seller Portal',
    this.portalSubtitle = 'Manage your fleet',
    required this.activeSection,
    this.onSectionSelected,
    required this.onListVehicle,
    this.onSettings,
    this.onSupport,
    this.showSellerSections = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(right: BorderSide(color: palette.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: palette.secondary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(portalTitle, style: DashboardTypography.headlineMd(palette).copyWith(color: palette.primary)),
                const SizedBox(height: 4),
                Text(portalSubtitle, style: DashboardTypography.bodySm(palette)),
              ],
            ),
          ),
          Divider(height: 1, color: palette.surfaceVariant),
          const SizedBox(height: 8),
          if (showSellerSections) ...[
            _PortalNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              selected: activeSection == DashboardPortalSection.dashboard,
              onTap: () => onSectionSelected?.call(DashboardPortalSection.dashboard),
            ),
            _PortalNavItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Orders',
              selected: activeSection == DashboardPortalSection.orders,
              onTap: () => onSectionSelected?.call(DashboardPortalSection.orders),
            ),
            _PortalNavItem(
              icon: Icons.history,
              label: 'Service History',
              selected: activeSection == DashboardPortalSection.serviceHistory,
              onTap: () => onSectionSelected?.call(DashboardPortalSection.serviceHistory),
            ),
            _PortalNavItem(
              icon: Icons.insights_outlined,
              label: 'Analytics',
              selected: activeSection == DashboardPortalSection.analytics,
              onTap: () => onSectionSelected?.call(DashboardPortalSection.analytics),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardPillButton(
                  label: 'List Vehicle',
                  icon: Icons.add,
                  onPressed: onListVehicle,
                ),
                if (onSettings != null) ...[
                  const SizedBox(height: 12),
                  _PortalNavItem(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    selected: activeSection == DashboardPortalSection.settings,
                    onTap: () {
                      onSectionSelected?.call(DashboardPortalSection.settings);
                      onSettings!();
                    },
                  ),
                ],
                if (onSupport != null) ...[
                  _PortalNavItem(
                    icon: Icons.support_agent_outlined,
                    label: 'Support',
                    selected: activeSection == DashboardPortalSection.support,
                    onTap: () => onSectionSelected?.call(DashboardPortalSection.support),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _PortalNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (selected)
              Positioned(
                left: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Icon(icon, size: 22, color: selected ? palette.primary : palette.body),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: DashboardTypography.labelLg(palette).copyWith(
                        color: selected ? palette.primary : palette.body,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardOutlinedAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const DashboardOutlinedAction({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: palette.title),
      label: Text(label, style: DashboardTypography.labelLg(palette)),
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.title,
        side: BorderSide(color: palette.outline),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
      ),
    );
  }
}

class DashboardHeroSearch extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hint;
  final VoidCallback? onSearch;

  const DashboardHeroSearch({
    super.key,
    required this.title,
    required this.subtitle,
    this.hint = 'Search for questions, features, or guides...',
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardCard(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      elevated: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -20,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.secondaryContainer.withValues(alpha: 0.35),
              ),
            ),
          ),
          Column(
            children: [
              Text(title, style: DashboardTypography.headlineLg(palette), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: DashboardTypography.bodyLg(palette),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 520;
                  if (narrow) {
                    return Column(
                      children: [
                        _SearchField(palette: palette, hint: hint),
                        const SizedBox(height: 12),
                        DashboardPillButton(label: 'Search', onPressed: onSearch),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _SearchField(palette: palette, hint: hint)),
                      const SizedBox(width: 12),
                      DashboardPillButton(label: 'Search', onPressed: onSearch),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final DashboardPalette palette;
  final String hint;

  const _SearchField({required this.palette, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      onTap: () {},
      style: DashboardTypography.bodyMd(palette).copyWith(color: palette.title),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: DashboardTypography.bodyMd(palette),
        prefixIcon: Icon(Icons.search, color: palette.muted),
        filled: true,
        fillColor: palette.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusPill),
          borderSide: BorderSide(color: palette.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusPill),
          borderSide: BorderSide(color: palette.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(palette.radiusPill),
          borderSide: BorderSide(color: palette.primary, width: 2),
        ),
      ),
    );
  }
}

class DashboardFaqTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconBackground;

  const DashboardFaqTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return DashboardCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBackground ?? palette.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: palette.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashboardTypography.labelLg(palette)),
                const SizedBox(height: 4),
                Text(description, style: DashboardTypography.bodySm(palette)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardLiveBadge extends StatelessWidget {
  final String label;

  const DashboardLiveBadge({super.key, this.label = 'All Systems Active'});

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.successSurface,
        borderRadius: BorderRadius.circular(palette.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: palette.success, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: DashboardTypography.labelMd(palette).copyWith(
              color: palette.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
