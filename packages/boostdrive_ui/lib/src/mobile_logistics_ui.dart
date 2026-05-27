import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'dashboard_theme_toggle.dart';
import 'mobile_provider_ui.dart';
import 'provider_dashboard_ui.dart';

/// Kinetic Precision UI for BaTLorriH logistics (Stitch exports).
class MobileLogisticsUi {
  MobileLogisticsUi._();

  static const double marginMobile = MobileProviderUi.marginMobile;
  static const double radiusCard = MobileProviderUi.radiusCard;
  static const Color kineticOrange = MobileProviderUi.kineticOrange;

  static BoxDecoration premiumCard(DashboardPalette palette) =>
      MobileProviderUi.premiumCard(palette);

  static String orderDisplayTitle({
    required String orderId,
    Map<String, dynamic>? items,
  }) {
    if (items != null) {
      for (final key in ['name', 'title', 'description', 'productName']) {
        final v = items[key];
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      }
    }
    final short = orderId.length > 8
        ? orderId.substring(0, 8).toUpperCase()
        : orderId.toUpperCase();
    return 'Order #$short';
  }

  static String statusBadgeLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'picking_up':
        return 'In Progress';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  static double statusProgress(String status) {
    switch (status) {
      case 'picking_up':
        return 0.5;
      case 'in_transit':
        return 0.85;
      case 'delivered':
        return 1.0;
      default:
        return 0.15;
    }
  }

  /// Active shift header with pulse indicator and status chips.
  static Widget shiftHeader({
    required DashboardPalette palette,
    required String partnerName,
    List<String> chips = const ['ON DUTY', 'LIVE GPS'],
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _PulsingDot(color: kineticOrange),
              const SizedBox(width: 8),
              Text(
                'ACTIVE SHIFT',
                style: DashboardTypography.labelMd(palette).copyWith(
                  color: kineticOrange,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'BaTLorriH Logistics: $partnerName',
            style: DashboardTypography.headlineMd(
              palette,
            ).copyWith(fontWeight: FontWeight.w800, height: 1.2),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.isDark
                          ? palette.surfaceContainer
                          : palette.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: palette.isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    child: Text(
                      c,
                      style: DashboardTypography.labelMd(palette).copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  static Widget metricsRow({
    required DashboardPalette palette,
    required String revenueLabel,
    required String revenueValue,
    required String jobsLabel,
    required String jobsValue,
    String? revenueTrend,
    String? jobsTrend,
  }) {
    return Row(
      children: [
        Expanded(
          child: _metricTile(
            palette: palette,
            label: revenueLabel,
            value: revenueValue,
            trend: revenueTrend,
            trendUp: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricTile(
            palette: palette,
            label: jobsLabel,
            value: jobsValue,
            trend: jobsTrend,
            trendUp: true,
            trendIcon: Icons.check_circle_outline,
          ),
        ),
      ],
    );
  }

  static Widget focusCardsRow({
    required DashboardPalette palette,
    required List<({IconData icon, String label})> items,
  }) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _focusCard(
              palette: palette,
              icon: items[i].icon,
              label: items[i].label,
            ),
          ),
        ],
      ],
    );
  }

  /// Map shell with live bar, optional next drop-off card, fullscreen FAB.
  static Widget liveDispatchMap({
    required DashboardPalette palette,
    required Widget mapChild,
    required VoidCallback onFullscreen,
    String? nextDropoffLabel,
    String? nextDropoffAddress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'LIVE DISPATCH MAP',
            style: DashboardTypography.labelMd(
              palette,
            ).copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(radiusCard),
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                mapChild,
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: ProviderDashboardUi.mapLiveStatusBar(
                    palette,
                    activeCount: 1,
                  ),
                ),
                if (nextDropoffAddress != null && nextDropoffAddress.isNotEmpty)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: MobileProviderUi.glassCard(palette),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: kineticOrange,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nextDropoffLabel ?? 'Next Drop-off',
                                  style: DashboardTypography.labelMd(palette)
                                      .copyWith(
                                        color: palette.onSurfaceVariant,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  nextDropoffAddress,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: DashboardTypography.bodyMd(
                                    palette,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  right: 12,
                  bottom:
                      nextDropoffAddress != null &&
                          nextDropoffAddress.isNotEmpty
                      ? 72
                      : 12,
                  child: Material(
                    color: kineticOrange,
                    elevation: 4,
                    shadowColor: kineticOrange.withValues(alpha: 0.4),
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: onFullscreen,
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget orderTabs({
    required DashboardPalette palette,
    required int selectedIndex,
    required ValueChanged<int> onChanged,
    required List<String> labels,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        labels[i],
                        style: DashboardTypography.labelMd(palette).copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: selectedIndex == i
                              ? kineticOrange
                              : palette.onSurfaceVariant,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 3,
                      decoration: BoxDecoration(
                        color: selectedIndex == i
                            ? kineticOrange
                            : Colors.transparent,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget logisticsOrderCard({
    required DashboardPalette palette,
    required String title,
    required String subtitle,
    required String status,
    required IconData leadingIcon,
    bool highlightBorder = false,
    Widget? trailingBadge,
    List<({String label, String value})>? statCells,
    double? progress,
    String? progressLabel,
    List<Widget>? actions,
  }) {
    final badge =
        trailingBadge ??
        Align(
          alignment: Alignment.topRight,
          child: _statusChip(palette: palette, status: status),
        );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(palette).copyWith(
        border: Border.all(
          color: highlightBorder
              ? kineticOrange.withValues(alpha: palette.isDark ? 0.45 : 0.35)
              : (palette.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05)),
          width: highlightBorder ? 1.5 : 1,
        ),
        boxShadow: highlightBorder && !palette.isDark
            ? [
                BoxShadow(
                  color: kineticOrange.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : premiumCard(palette).boxShadow,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: kineticOrange.withValues(
                          alpha: palette.isDark ? 0.15 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(leadingIcon, color: kineticOrange, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 72),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: DashboardTypography.labelLg(
                                palette,
                              ).copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: DashboardTypography.bodyMd(
                                palette,
                              ).copyWith(color: palette.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (statCells != null && statCells.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var i = 0; i < statCells.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _miniStat(
                            palette: palette,
                            label: statCells[i].label,
                            value: statCells[i].value,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (progress != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        progressLabel ?? 'LOADING PROGRESS',
                        style: DashboardTypography.labelMd(palette).copyWith(
                          color: palette.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${(progress * 100).round()}%',
                        style: DashboardTypography.labelMd(palette).copyWith(
                          color: kineticOrange,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: palette.isDark
                          ? palette.surfaceContainerHighest
                          : palette.surfaceContainerHigh,
                      color: kineticOrange,
                    ),
                  ),
                ],
                if (actions != null && actions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...actions,
                ],
              ],
            ),
          ),
          badge,
        ],
      ),
    );
  }

  static Widget primaryActionButton({
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
  }) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
    final btn = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: kineticOrange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: kineticOrange.withValues(alpha: 0.35),
      ),
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  static Widget secondaryActionButton({
    required DashboardPalette palette,
    required String label,
    required VoidCallback? onPressed,
    bool expanded = true,
  }) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.title,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: palette.isDark
            ? palette.surfaceContainer
            : palette.surfaceContainerHigh,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  static Widget actionRow({
    required DashboardPalette palette,
    required Widget secondary,
    required Widget primary,
    int primaryFlex = 2,
  }) {
    return Row(
      children: [
        Expanded(child: secondary),
        const SizedBox(width: 8),
        Expanded(flex: primaryFlex, child: primary),
      ],
    );
  }

  static Widget deliveredOrderCard({
    required DashboardPalette palette,
    required String title,
    String? subtitle,
    required String destination,
    required String completedLabel,
    required VoidCallback onView,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusChip(palette: palette, status: 'delivered'),
              const Spacer(),
              IconButton(
                onPressed: onView,
                style: IconButton.styleFrom(
                  backgroundColor: palette.isDark
                      ? palette.surfaceContainer
                      : palette.surfaceContainerHigh,
                  foregroundColor: kineticOrange,
                ),
                icon: const Icon(Icons.visibility_outlined, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: DashboardTypography.headlineMd(
              palette,
            ).copyWith(fontWeight: FontWeight.w800, height: 1.25),
          ),
          if (subtitle != null && subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: DashboardTypography.bodyLg(
                  palette,
                ).copyWith(color: palette.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  palette: palette,
                  label: 'DESTINATION',
                  value: destination,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                  palette: palette,
                  label: 'COMPLETED',
                  value: completedLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: secondaryActionButton(
              palette: palette,
              label: 'VIEW DETAILS',
              onPressed: onView,
            ),
          ),
        ],
      ),
    );
  }

  static Widget emptyOrders({
    required DashboardPalette palette,
    required String message,
  }) {
    return MobileProviderUi.emptyStateCard(
      palette: palette,
      icon: Icons.local_shipping_outlined,
      message: message,
    );
  }

  // —— Order tracking detail ——

  static PreferredSizeWidget trackingAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    VoidCallback? onContact,
  }) {
    return AppBar(
      backgroundColor: palette.background.withValues(alpha: 0.92),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        'Order Tracking',
        style: DashboardTypography.headlineMd(
          palette,
        ).copyWith(fontWeight: FontWeight.w800),
      ),
      actions: [
        TextButton(
          onPressed: onContact,
          child: Text(
            'CONTACT',
            style: DashboardTypography.labelLg(
              palette,
            ).copyWith(color: kineticOrange, fontWeight: FontWeight.w800),
          ),
        ),
        const DashboardThemeToggle(),
        const SizedBox(width: 4),
      ],
    );
  }

  static Widget trackingMapHero({
    required DashboardPalette palette,
    String? etaLabel,
    String? etaValue,
  }) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette.isDark
                    ? [const Color(0xFF1A2332), const Color(0xFF0D1117)]
                    : [const Color(0xFFE8EDF2), const Color(0xFFD0D9E2)],
              ),
            ),
            child: CustomPaint(painter: _MapGridPainter(palette: palette)),
          ),
          Center(
            child: Icon(
              Icons.route,
              size: 64,
              color: palette.onSurfaceVariant.withValues(alpha: 0.35),
            ),
          ),
          if (etaValue != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: MobileProviderUi.glassCard(palette),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kineticOrange.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.schedule,
                        color: kineticOrange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            etaLabel ?? 'Estimated arrival',
                            style: DashboardTypography.labelMd(
                              palette,
                            ).copyWith(color: palette.onSurfaceVariant),
                          ),
                          Text(
                            etaValue,
                            style: DashboardTypography.headlineMd(
                              palette,
                            ).copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget trackingStepper({
    required DashboardPalette palette,
    required List<({String label, bool complete, bool active})> steps,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: marginMobile),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            if (i > 0)
              _stepConnector(palette: palette, complete: steps[i - 1].complete),
            _stepNode(palette: palette, step: steps[i]),
          ],
        ],
      ),
    );
  }

  static Widget trackingInfoCard({
    required DashboardPalette palette,
    required String title,
    required List<({String label, String value})> rows,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginMobile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: premiumCard(palette),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: DashboardTypography.labelMd(palette).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: palette.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      rows[i].label,
                      style: DashboardTypography.bodyMd(
                        palette,
                      ).copyWith(color: palette.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      rows[i].value,
                      textAlign: TextAlign.end,
                      style: DashboardTypography.bodyMd(
                        palette,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget trackingPartnerCard({
    required DashboardPalette palette,
    required String name,
    required String role,
    VoidCallback? onCall,
    VoidCallback? onMessage,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginMobile),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: premiumCard(palette),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: kineticOrange.withValues(alpha: 0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: kineticOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: DashboardTypography.labelLg(
                      palette,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    role,
                    style: DashboardTypography.bodySm(
                      palette,
                    ).copyWith(color: palette.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onCall,
              icon: const Icon(Icons.call, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: palette.isDark
                    ? palette.surfaceContainer
                    : palette.surfaceContainerHigh,
                foregroundColor: kineticOrange,
              ),
            ),
            const SizedBox(width: 4),
            IconButton.filledTonal(
              onPressed: onMessage,
              icon: const Icon(Icons.message_outlined, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: kineticOrange.withValues(alpha: 0.12),
                foregroundColor: kineticOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget trackingHistorySection({
    required DashboardPalette palette,
    required List<({String title, String time, bool isLatest})> events,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: marginMobile),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'UPDATE HISTORY',
            style: DashboardTypography.labelMd(palette).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: palette.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...events.map(
            (e) => _timelineRow(
              palette: palette,
              title: e.title,
              time: e.time,
              isLatest: e.isLatest,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip({
    required DashboardPalette palette,
    required String status,
  }) {
    final label = statusBadgeLabel(status);
    final isDelivered = status == 'delivered';
    final isTransit = status == 'in_transit' || status == 'picking_up';
    final color = isDelivered
        ? const Color(0xFF2E7D32)
        : (isTransit ? kineticOrange : palette.onSurfaceVariant);
    final bg = isDelivered
        ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
        : kineticOrange.withValues(alpha: palette.isDark ? 0.15 : 0.1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label.toUpperCase(),
        style: DashboardTypography.labelMd(palette).copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 9,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static Widget _metricTile({
    required DashboardPalette palette,
    required String label,
    required String value,
    String? trend,
    bool trendUp = true,
    IconData trendIcon = Icons.trending_up,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: premiumCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DashboardTypography.labelMd(palette).copyWith(
              color: palette.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: DashboardTypography.headlineMd(
              palette,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          if (trend != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  trendIcon,
                  size: 14,
                  color: trendUp ? const Color(0xFF2E7D32) : palette.error,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trend,
                    style: DashboardTypography.labelMd(palette).copyWith(
                      color: trendUp ? const Color(0xFF2E7D32) : palette.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static Widget _focusCard({
    required DashboardPalette palette,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: premiumCard(palette),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kineticOrange.withValues(
                alpha: palette.isDark ? 0.15 : 0.1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kineticOrange, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.labelMd(palette).copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _miniStat({
    required DashboardPalette palette,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.isDark
            ? palette.surfaceContainer
            : palette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DashboardTypography.labelMd(palette).copyWith(
              fontSize: 9,
              color: palette.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.labelLg(
              palette,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  static Widget _stepNode({
    required DashboardPalette palette,
    required ({String label, bool complete, bool active}) step,
  }) {
    final filled = step.complete || step.active;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? kineticOrange : palette.surfaceContainerHigh,
            border: Border.all(
              color: step.active ? kineticOrange : Colors.transparent,
              width: 2,
            ),
            boxShadow: step.active
                ? [
                    BoxShadow(
                      color: kineticOrange.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            step.complete ? Icons.check : Icons.circle,
            size: step.complete ? 18 : 10,
            color: filled ? Colors.white : palette.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 72,
          child: Text(
            step.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: DashboardTypography.labelMd(palette).copyWith(
              fontWeight: step.active ? FontWeight.w800 : FontWeight.w500,
              color: step.active ? kineticOrange : palette.onSurfaceVariant,
              fontSize: 9,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _stepConnector({
    required DashboardPalette palette,
    required bool complete,
  }) {
    return Container(
      width: 32,
      height: 2,
      margin: const EdgeInsets.only(bottom: 28),
      color: complete ? kineticOrange : palette.surfaceContainerHighest,
    );
  }

  static Widget _timelineRow({
    required DashboardPalette palette,
    required String title,
    required String time,
    required bool isLatest,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLatest
                      ? kineticOrange
                      : palette.surfaceContainerHighest,
                  border: isLatest
                      ? Border.all(
                          color: kineticOrange.withValues(alpha: 0.5),
                          width: 3,
                        )
                      : null,
                ),
              ),
              if (!isLatest)
                Container(
                  width: 2,
                  height: 40,
                  color: palette.surfaceContainerHighest,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: DashboardTypography.bodyMd(palette).copyWith(
                    fontWeight: isLatest ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
                Text(
                  time,
                  style: DashboardTypography.labelMd(
                    palette,
                  ).copyWith(color: palette.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.4 + _controller.value * 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(
                  alpha: 0.3 + _controller.value * 0.3,
                ),
                blurRadius: 6 + _controller.value * 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  _MapGridPainter({required this.palette});

  final DashboardPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = palette.onSurfaceVariant.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    const step = 32.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) =>
      oldDelegate.palette != palette;
}
