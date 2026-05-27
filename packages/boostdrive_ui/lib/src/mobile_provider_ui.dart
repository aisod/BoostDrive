import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'dashboard_theme_toggle.dart';
import 'mobile_customer_ui.dart';

/// Kinetic Precision UI for mobile service-provider screens (Stitch exports).
class MobileProviderUi {
  MobileProviderUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;
  static const Color kineticOrange = Color(0xFFFF6600);

  static Color cardSurface(DashboardPalette palette) =>
      palette.isDark ? palette.surfaceContainerLow : palette.surfaceContainerLowest;

  static Color fieldSurface(DashboardPalette palette) =>
      palette.isDark ? palette.surfaceContainer : palette.surfaceContainerLow;

  static BoxDecoration premiumCard(DashboardPalette palette) {
    return BoxDecoration(
      color: cardSurface(palette),
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(
        color: palette.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
      ),
      boxShadow: palette.isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
    );
  }

  static BoxDecoration glassCard(DashboardPalette palette) {
    return BoxDecoration(
      color: palette.isDark
          ? palette.surfaceContainerLow.withValues(alpha: 0.92)
          : palette.surfaceContainerLowest.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(
        color: palette.primaryContainer.withValues(alpha: palette.isDark ? 0.15 : 0.2),
      ),
    );
  }

  /// Frosted top bar: avatar + orange title + theme toggle + optional trailing.
  static PreferredSizeWidget glassAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    required String title,
    Widget? avatar,
    List<Widget>? trailing,
    bool showBack = false,
    bool showThemeToggle = true,
  }) {
    final barBg = palette.isDark
        ? palette.background.withValues(alpha: 0.94)
        : palette.surfaceContainerLowest.withValues(alpha: 0.85);
    final accent = palette.primaryContainer;

    final actions = <Widget>[
      if (showThemeToggle)
        DashboardThemeToggle(compact: true, onColoredHeader: false),
      ...?trailing,
    ];

    return AppBar(
      backgroundColor: barBg,
      foregroundColor: accent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: showBack,
      leading: showBack
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: palette.title),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
      title: Row(
        children: [
          if (avatar != null) ...[
            avatar,
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.manrope(
                fontSize: title.length > 12 ? 22 : 28,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: -0.5,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  static Widget profileAvatar({
    required DashboardPalette palette,
    String? imageUrl,
    double radius = 20,
    bool orangeRing = true,
  }) {
    return Container(
      padding: orangeRing ? const EdgeInsets.all(2) : EdgeInsets.zero,
      decoration: orangeRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: palette.primaryContainer, width: 2),
            )
          : null,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: palette.surfaceContainerHigh,
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(Icons.person, color: palette.primaryContainer, size: radius)
            : null,
      ),
    );
  }

  /// Provider Hub tabs (MY SERVICES / BATLORRIH).
  static Widget hubTabBar({
    required DashboardPalette palette,
    required TabController controller,
    required List<Tab> tabs,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(marginMobile, 8, marginMobile, 0),
      decoration: BoxDecoration(
        color: fieldSurface(palette),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: palette.primaryContainer,
          borderRadius: BorderRadius.circular(radiusControl - 2),
          boxShadow: [
            BoxShadow(
              color: palette.primaryContainer.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: palette.muted,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
        tabs: tabs,
      ),
    );
  }

  /// Orders segment control (SOS / REQUESTS / HISTORY).
  static Widget segmentTabBar({
    required DashboardPalette palette,
    required TabController controller,
    required List<String> labels,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: marginMobile),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: fieldSurface(palette),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: palette.primaryContainer,
          borderRadius: BorderRadius.circular(radiusControl - 2),
          boxShadow: [
            BoxShadow(
              color: palette.primaryContainer.withValues(alpha: 0.3),
              blurRadius: 6,
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: palette.muted,
        labelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: labels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }

  static Widget sectionTitle(DashboardPalette palette, String text) {
    return Text(
      text.toUpperCase(),
      style: DashboardTypography.labelMd(palette).copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w800,
        color: palette.muted,
      ),
    );
  }

  static Widget pageHeader({
    required DashboardPalette palette,
    required String title,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.manrope(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: palette.title,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: DashboardTypography.bodyMd(palette).copyWith(color: palette.muted),
          ),
        ],
      ],
    );
  }

  /// Bento stat tile (inventory / services summary grid).
  static Widget bentoStatCard({
    required DashboardPalette palette,
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainerHigh : palette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor ?? palette.primaryContainer, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: DashboardTypography.labelMd(palette).copyWith(color: palette.muted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: valueColor ?? palette.title,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  static InputDecoration searchDecoration(DashboardPalette palette, {String? hint}) {
    return InputDecoration(
      hintText: hint ?? 'Search…',
      hintStyle: DashboardTypography.bodyMd(palette).copyWith(color: palette.muted),
      prefixIcon: Icon(Icons.search, color: palette.muted),
      filled: true,
      fillColor: fieldSurface(palette),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.primaryContainer, width: 2),
      ),
    );
  }

  static Widget primaryButton({
    required DashboardPalette palette,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
  }) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );

    final btn = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: palette.primaryContainer,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        elevation: palette.isDark ? 0 : 2,
        shadowColor: palette.primaryContainer.withValues(alpha: 0.35),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  static Widget outlineButton({
    required DashboardPalette palette,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool expanded = true,
  }) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: palette.primaryContainer),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.primaryContainer,
          ),
        ),
      ],
    );

    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primaryContainer,
        side: BorderSide(color: palette.primaryContainer, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }

  /// Glass SOS / order card shell — content and actions supplied by caller.
  static Widget glassOrderCard({
    required DashboardPalette palette,
    required Widget child,
    Widget? footer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: glassCard(palette),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.all(20), child: child),
          if (footer != null) footer,
        ],
      ),
    );
  }

  static Widget urgencyBadge({
    required DashboardPalette palette,
    required String label,
    bool critical = false,
  }) {
    final bg = critical
        ? palette.error.withValues(alpha: palette.isDark ? 0.35 : 0.15)
        : palette.surfaceContainerHighest;
    final fg = critical ? palette.error : palette.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: critical ? Border.all(color: palette.error.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: fg,
        ),
      ),
    );
  }

  static Widget metricChip({
    required DashboardPalette palette,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fieldSurface(palette),
        borderRadius: BorderRadius.circular(radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: DashboardTypography.labelMd(palette).copyWith(
              color: palette.muted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.title,
            ),
          ),
        ],
      ),
    );
  }

  /// List section with rounded container (stock details table wrapper).
  static Widget listSection({
    required DashboardPalette palette,
    required String title,
    required Widget child,
    List<Widget>? headerActions,
  }) {
    return Container(
      decoration: premiumCard(palette),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: fieldSurface(palette),
              border: Border(
                bottom: BorderSide(
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: palette.title,
                    ),
                  ),
                ),
                if (headerActions != null) ...headerActions,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  static Widget listTileCard({
    required DashboardPalette palette,
    required Widget title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: DashboardTypography.bodySm(palette),
                        child: subtitle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  static Widget serviceCatalogCard({
    required DashboardPalette palette,
    required String name,
    required String category,
    required String priceLabel,
    required String durationLabel,
    required String description,
    required bool active,
    required ValueChanged<bool>? onActiveChanged,
    required VoidCallback? onEdit,
    required VoidCallback? onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: premiumCard(palette),
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
                  color: palette.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(radiusControl),
                ),
                child: Icon(Icons.handyman, color: palette.primaryContainer, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        category,
                        style: DashboardTypography.labelMd(palette).copyWith(
                          color: palette.muted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: active,
                onChanged: onActiveChanged,
                activeThumbColor: Colors.white,
                activeTrackColor: palette.primaryContainer,
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(description, style: DashboardTypography.bodySm(palette)),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STANDARD PRICE',
                      style: DashboardTypography.labelMd(palette).copyWith(
                        color: palette.muted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      priceLabel,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(durationLabel, style: DashboardTypography.bodySm(palette)),
                  ],
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  backgroundColor: palette.surfaceContainerHighest,
                  foregroundColor: palette.title,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusControl),
                  ),
                ),
                child: Text(
                  'Edit Details',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: palette.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget sectionHeader({
    required DashboardPalette palette,
    required String title,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: palette.title,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  /// Online / offline segmented control (service pro dashboard).
  static Widget availabilityToggle({
    required DashboardPalette palette,
    required bool isOnline,
    required bool updating,
    required ValueChanged<bool> onChanged,
    String? statusHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(palette, 'Availability status'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: fieldSurface(palette),
            borderRadius: BorderRadius.circular(radiusCard),
            border: Border.all(
              color: palette.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _availabilitySegment(
                  palette: palette,
                  label: 'AVAILABLE',
                  icon: Icons.wifi_tethering,
                  selected: isOnline,
                  enabled: !updating,
                  onTap: () => onChanged(true),
                ),
              ),
              Expanded(
                child: _availabilitySegment(
                  palette: palette,
                  label: 'OFFLINE',
                  icon: Icons.power_settings_new,
                  selected: !isOnline,
                  enabled: !updating,
                  onTap: () => onChanged(false),
                ),
              ),
            ],
          ),
        ),
        if (updating)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              'Updating availability…',
              style: DashboardTypography.bodySm(palette).copyWith(
                color: palette.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (statusHint != null && statusHint.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              statusHint,
              style: DashboardTypography.bodySm(palette).copyWith(
                color: palette.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  static Widget _availabilitySegment({
    required DashboardPalette palette,
    required String label,
    required IconData icon,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final fg = selected ? Colors.white : palette.muted.withValues(alpha: 0.55);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? palette.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(radiusControl),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: palette.primaryContainer.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.montserrat(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Compact earnings / jobs / rating tile (service pro dashboard row).
  static Widget compactStatCard({
    required DashboardPalette palette,
    required String label,
    required String value,
    required String subtext,
    Color? subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainerHigh : palette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radiusCard),
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
              color: palette.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: palette.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext.toUpperCase(),
            style: DashboardTypography.labelMd(palette).copyWith(
              color: subtextColor ?? palette.primaryContainer,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static Widget emptyStateCard({
    required DashboardPalette palette,
    required String message,
    IconData icon = Icons.inbox_outlined,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: premiumCard(palette),
      child: Column(
        children: [
          Icon(icon, size: 40, color: palette.muted.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: DashboardTypography.bodySm(palette).copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }

  static InputDecoration fieldDecoration(
    DashboardPalette palette, {
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: DashboardTypography.bodyMd(palette).copyWith(color: palette.muted),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: fieldSurface(palette),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.primaryContainer, width: 2),
      ),
    );
  }

  static Widget stockStatusChip({
    required DashboardPalette palette,
    required String label,
    bool lowStock = false,
  }) {
    final bg = lowStock
        ? palette.error.withValues(alpha: palette.isDark ? 0.35 : 0.2)
        : palette.success.withValues(alpha: palette.isDark ? 0.2 : 0.12);
    final fg = lowStock ? palette.error : palette.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  /// Themed alert dialog shell — preserves behavior, matches Kinetic surfaces.
  static AlertDialog kineticAlertDialog({
    required DashboardPalette palette,
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: cardSurface(palette),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
      title: DefaultTextStyle(
        style: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: palette.title,
        ),
        child: title,
      ),
      content: DefaultTextStyle(
        style: DashboardTypography.bodyMd(palette),
        child: content,
      ),
      actions: actions,
    );
  }

  static Widget floatingEtaBadge({
    required DashboardPalette palette,
    required String etaLabel,
    required String distanceLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.isDark
            ? palette.surfaceContainerLow.withValues(alpha: 0.92)
            : palette.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: palette.primaryContainer.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.route, color: palette.primaryContainer),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTIMATED ARRIVAL',
                style: DashboardTypography.labelMd(palette).copyWith(
                  color: palette.muted,
                  fontSize: 10,
                ),
              ),
              Text(
                '$etaLabel ($distanceLabel)',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: palette.title,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
