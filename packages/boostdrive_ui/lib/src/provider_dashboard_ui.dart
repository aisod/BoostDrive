import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'dashboard_ui_components.dart';

/// Stitch-aligned UI helpers for Service Provider + BaTLorriH logistics dashboards.
class ProviderDashboardUi {
  ProviderDashboardUi._();

  static BoxDecoration surfaceCard(
    DashboardPalette palette, {
    bool glass = false,
    Color? borderAccent,
  }) {
    return BoxDecoration(
      color: glass
          ? palette.surfaceContainerLowest.withValues(alpha: palette.isDark ? 0.92 : 0.9)
          : palette.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: borderAccent ?? palette.outlineVariant.withValues(alpha: palette.isDark ? 0.15 : 0.35),
      ),
      boxShadow: palette.isDark ? null : palette.cardShadowLow,
    );
  }

  /// Horizontal section tabs (HOME, ROUTES, FLEET, …).
  static Widget sectionNav({
    required DashboardPalette palette,
    required List<ProviderSectionNavItem> items,
    required String currentId,
    required ValueChanged<String> onSelected,
    bool scrollable = true,
  }) {
    final bar = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final active = currentId == item.id;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Material(
              color: active ? palette.surfaceContainerHigh : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onSelected(item.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: active ? palette.primary : palette.muted,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: active ? palette.onBackground : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    if (!scrollable) return bar;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: bar,
    );
  }

  /// Service Pro dashboard hero header.
  static Widget serviceProHeader({
    required DashboardPalette palette,
    required String displayName,
    required String categorySubtitle,
    required Widget avatar,
    required Widget notificationBell,
    required String earningsValue,
    bool verified = false,
    bool compact = false,
  }) {
    final titleStyle = GoogleFonts.manrope(
      fontSize: compact ? 26 : 32,
      fontWeight: FontWeight.w800,
      color: palette.onBackground,
      letterSpacing: -0.5,
      height: 1.15,
    );

    Widget verifiedChip() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified, color: palette.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'VERIFIED',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: palette.primary,
                ),
              ),
            ],
          ),
        );

    final earningsCard = earningsSidebarCard(
      palette: palette,
      label: 'TOTAL EARNINGS',
      value: earningsValue,
      sublabel: 'LIFETIME',
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BoostDrive Pro: $displayName', style: titleStyle),
                    if (verified) ...[const SizedBox(height: 8), verifiedChip()],
                  ],
                ),
              ),
              notificationBell,
            ],
          ),
          const SizedBox(height: 10),
          Text(categorySubtitle, style: DashboardTypography.bodySm(palette)),
          const SizedBox(height: 16),
          earningsCard,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        avatar,
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text('BoostDrive Pro: $displayName', style: titleStyle),
                  if (verified) verifiedChip(),
                ],
              ),
              const SizedBox(height: 8),
              Text(categorySubtitle, style: DashboardTypography.bodyLg(palette)),
            ],
          ),
        ),
        notificationBell,
        const SizedBox(width: 16),
        SizedBox(width: 200, child: earningsCard),
      ],
    );
  }

  /// BaTLorriH logistics page header.
  static Widget logisticsHeader({
    required DashboardPalette palette,
    required String providerName,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BaTLorriH Logistics: $providerName',
          style: GoogleFonts.manrope(
            fontSize: compact ? 28 : 32,
            fontWeight: FontWeight.w800,
            color: palette.onBackground,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Parts Delivery • Vehicle Transport • Last-Mile Solutions',
          style: DashboardTypography.bodyLg(palette),
        ),
      ],
    );
  }

  /// Breadcrumb + uppercase section title (logistics finance, fleet, etc.).
  static Widget logisticsSectionTitle({
    required DashboardPalette palette,
    required String section,
    String hubLabel = 'LOGISTICS (BATLORRIH)',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(hubLabel, style: DashboardTypography.labelMd(palette)),
            Text(' / ', style: DashboardTypography.labelMd(palette)),
            Text(
              section,
              style: DashboardTypography.labelMd(palette).copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          section,
          style: GoogleFonts.manrope(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: palette.onBackground,
          ),
        ),
      ],
    );
  }

  static Widget earningsSidebarCard({
    required DashboardPalette palette,
    required String label,
    required String value,
    String? sublabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: palette.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: palette.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.onBackground,
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 4),
            Text(
              sublabel,
              style: DashboardTypography.labelMd(palette).copyWith(
                color: palette.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Metric tile for logistics HOME / finance grids.
  static Widget metricTile({
    required DashboardPalette palette,
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    Color? accent,
    bool highlightBorder = false,
  }) {
    final color = accent ?? palette.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: highlightBorder
            ? Border(
                left: BorderSide(color: palette.primary, width: 4),
                top: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
                right: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
                bottom: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
              )
            : Border.all(color: palette.outlineVariant.withValues(alpha: 0.35)),
        boxShadow: palette.isDark ? null : palette.cardShadowLow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: DashboardTypography.labelMd(palette).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.onBackground,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtext,
            style: DashboardTypography.labelMd(palette).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget purposeCard({
    required DashboardPalette palette,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaceCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary, size: 26),
          const SizedBox(height: 14),
          Text(title, style: DashboardTypography.labelLg(palette)),
          const SizedBox(height: 8),
          Text(description, style: DashboardTypography.bodySm(palette)),
        ],
      ),
    );
  }

  static Widget emptyPanel({
    required DashboardPalette palette,
    required IconData icon,
    required String title,
    String? message,
    Widget? action,
    double minHeight = 200,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(32),
      decoration: surfaceCard(palette),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: palette.muted.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(title, style: DashboardTypography.headlineMd(palette)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: DashboardTypography.bodySm(palette),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action],
          ],
        ),
      ),
    );
  }

  /// Floating dispatch overview on routes map.
  static Widget dispatchOverviewCard({
    required DashboardPalette palette,
    required List<({String label, String value, IconData icon})> stats,
    VoidCallback? onManage,
  }) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surfaceContainerHighest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.15)),
        boxShadow: palette.cardShadowHigh,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'DISPATCH OVERVIEW',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: palette.primary,
                  ),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.map((s) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.label, style: DashboardTypography.bodySm(palette)),
                        Text(
                          s.value,
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: palette.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(s.icon, color: palette.muted, size: 22),
                ],
              ),
            );
          }),
          if (onManage != null) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onManage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.primaryContainer,
                  foregroundColor: palette.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'MANAGE DISPATCH',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget mapLiveStatusBar(DashboardPalette palette, {required int activeCount}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceContainerLow.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: palette.primary, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            'LIVE DISPATCHING',
            style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: palette.onBackground),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            width: 1,
            height: 16,
            color: palette.outlineVariant.withValues(alpha: 0.4),
          ),
          Icon(Icons.satellite_alt, size: 16, color: palette.muted),
          const SizedBox(width: 6),
          Text('GPS SYNCED', style: DashboardTypography.labelMd(palette)),
        ],
      ),
    );
  }

  static Widget primaryFilledButton({
    required DashboardPalette palette,
    required String label,
    VoidCallback? onPressed,
    IconData? icon,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.add, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primaryBright,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class ProviderSectionNavItem {
  final String id;
  final String label;
  final IconData icon;

  const ProviderSectionNavItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}
