import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';
import 'dashboard_theme_toggle.dart';

/// Kinetic Precision UI for emergency contacts directory (Stitch exports).
class EmergencyDirectoryUi {
  EmergencyDirectoryUi._();

  static const double marginMobile = 20;
  static const double radiusCard = 24;
  static const double radiusControl = 12;

  static IconData categoryIcon(String key) {
    return switch (key) {
      'police' => Icons.local_police_outlined,
      'ambulance' => Icons.medical_services_outlined,
      'towing' => Icons.car_crash_outlined,
      'mobile_mechanic' => Icons.build_circle_outlined,
      'fuel_refill' => Icons.local_gas_station_outlined,
      'flat_tire' => Icons.tire_repair_outlined,
      'accident' => Icons.warning_amber_rounded,
      _ => Icons.support_agent_outlined,
    };
  }

  static IconData categoryChipIcon(String key) {
    if (key == '__all__') return Icons.all_inclusive;
    return categoryIcon(key);
  }

  static PreferredSizeWidget appBar(BuildContext context, DashboardPalette palette) {
    final headerBg = palette.isDark
        ? palette.surface.withValues(alpha: 0.85)
        : const Color(0xFFF9F9F9).withValues(alpha: 0.85);
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE3BFB2);

    return AppBar(
      backgroundColor: headerBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: borderColor),
      ),
      leading: IconButton(
        onPressed: () => Navigator.maybePop(context),
        icon: Icon(Icons.arrow_back, color: palette.primaryContainer),
      ),
      title: Text(
        'BoostDrive',
        style: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: palette.primaryContainer,
          letterSpacing: -0.5,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 8),
          child: DashboardThemeToggle(compact: true, onColoredHeader: false),
        ),
      ],
    );
  }

  static Widget pageHeader(DashboardPalette palette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(marginMobile, 8, marginMobile, 0),
      child: Text(
        'Emergency Support',
        style: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          height: 1.25,
          color: palette.title,
        ),
      ),
    );
  }

  static Widget searchField({
    required DashboardPalette palette,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
  }) {
    final fill = palette.isDark ? palette.surfaceContainerLow : const Color(0xFFEEEEEE);
    final border = palette.isDark ? palette.surfaceContainerHighest : const Color(0xFFE3BFB2);

    return Padding(
      padding: const EdgeInsets.fromLTRB(marginMobile, 16, marginMobile, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.manrope(fontSize: 16, color: palette.title),
        decoration: InputDecoration(
          hintText: 'Search services, cities, or organizations...',
          hintStyle: GoogleFonts.manrope(
            fontSize: 16,
            color: palette.isDark ? palette.onSecondaryContainer : const Color(0xFF5A4138),
          ),
          prefixIcon: Icon(Icons.search, color: palette.onSurfaceVariant, size: 22),
          filled: true,
          fillColor: fill,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusControl),
            borderSide: BorderSide(color: palette.primaryContainer, width: 2),
          ),
        ),
      ),
    );
  }

  static Widget filterSectionLabel(DashboardPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(marginMobile, 20, marginMobile, 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: palette.isDark ? palette.onSurfaceVariant : const Color(0xFF5A4138),
        ),
      ),
    );
  }

  static Widget categoryChipRow({
    required DashboardPalette palette,
    required List<Widget> children,
  }) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: marginMobile),
        children: children,
      ),
    );
  }

  static Widget categoryChip({
    required DashboardPalette palette,
    required String label,
    required String categoryKey,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? palette.primaryContainer
                  : (palette.isDark ? palette.surfaceContainerHigh : const Color(0xFFEEEEEE)),
              borderRadius: BorderRadius.circular(999),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: palette.primaryContainer.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  categoryChipIcon(categoryKey),
                  size: 18,
                  color: selected ? Colors.white : palette.title,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : palette.title,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget regionChipRow({
    required DashboardPalette palette,
    required List<Widget> children,
  }) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(marginMobile, 0, marginMobile, 8),
        children: children,
      ),
    );
  }

  static Widget regionChip({
    required DashboardPalette palette,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusControl),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? palette.primaryContainer.withValues(alpha: 0.1)
                  : (palette.isDark ? palette.surfaceContainer : palette.surfaceContainerLow),
              borderRadius: BorderRadius.circular(radiusControl),
              border: Border.all(
                color: selected
                    ? palette.primaryContainer.withValues(alpha: 0.3)
                    : (palette.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFE3BFB2).withValues(alpha: 0.5)),
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.03,
                color: selected
                    ? (palette.isDark ? palette.primary : palette.primaryContainer)
                    : palette.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget contactCard({
    required DashboardPalette palette,
    required String categoryKey,
    required String categoryLabel,
    required String locality,
    required String title,
    String? organization,
    required String phone,
    String? secondaryPhone,
    String? notes,
    required VoidCallback onTap,
  }) {
    final cardColor = palette.isDark
        ? palette.surfaceContainerLow
        : Colors.white;
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFE3BFB2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(radiusCard),
            border: Border.all(color: borderColor),
            boxShadow: palette.isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (palette.isDark)
                Positioned(
                  top: -32,
                  right: -32,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primaryContainer.withValues(alpha: 0.05),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: palette.primaryContainer.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: palette.primaryContainer.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Text(
                                  categoryLabel.toUpperCase(),
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.03,
                                    color: palette.primaryContainer,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: GoogleFonts.manrope(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                  color: palette.title,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: palette.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      locality,
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        color: palette.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (organization != null && organization.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  organization,
                                  style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    color: palette.body,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.isDark
                                ? palette.surfaceContainerHigh
                                : const Color(0xFFF3F3F3),
                            borderRadius: BorderRadius.circular(radiusControl),
                          ),
                          child: Icon(
                            categoryIcon(categoryKey),
                            color: palette.primaryContainer,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.isDark
                            ? palette.surfaceContainer
                            : const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(radiusControl),
                        border: Border.all(
                          color: palette.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFE3BFB2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Main line',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: palette.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phone,
                                  style: GoogleFonts.manrope(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: palette.primaryContainer,
                                  ),
                                ),
                                if (secondaryPhone != null &&
                                    secondaryPhone.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    secondaryPhone,
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      color: palette.body,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF6600),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 22),
                          ),
                        ],
                      ),
                    ),
                    if (notes != null && notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        notes,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          height: 1.35,
                          color: palette.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget loadingState(DashboardPalette palette) {
    return Center(child: CircularProgressIndicator(color: palette.primaryContainer));
  }

  static Widget errorState({
    required DashboardPalette palette,
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(marginMobile),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: palette.muted),
            const SizedBox(height: 16),
            Text(
              'Could not load contacts',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: palette.title,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(fontSize: 13, color: palette.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryContainer,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusControl),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget emptyState({
    required DashboardPalette palette,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(marginMobile),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(fontSize: 16, color: palette.body, height: 1.5),
        ),
      ),
    );
  }

  /// Stitch contact-detail modal (same actions: call primary, copy, call alternate, dismiss).
  static Widget contactDetailDialog({
    required DashboardPalette palette,
    required String categoryKey,
    required String title,
    String? organization,
    required String primaryPhone,
    String? secondaryPhone,
    String? notes,
    required VoidCallback onClose,
    required VoidCallback onCopy,
    required VoidCallback onCallPrimary,
    VoidCallback? onCallAlternate,
  }) {
    final hasAlt = secondaryPhone != null && secondaryPhone.trim().isNotEmpty;
    final cardColor = palette.isDark
        ? palette.surfaceContainerHigh.withValues(alpha: 0.95)
        : Colors.white;
    final rowFill = palette.isDark
        ? palette.surface.withValues(alpha: 0.5)
        : const Color(0xFFF3F3F3);
    final rowBorder = palette.isDark
        ? Colors.white.withValues(alpha: 0.05)
        : const Color(0xFFE0E0E0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(marginMobile),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(radiusCard),
          border: Border.all(
            color: palette.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E0E0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: palette.isDark ? 0.5 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radiusCard),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Container(
                    height: 128,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          palette.isDark
                              ? palette.surfaceContainerHigh
                              : const Color(0xFF09151B),
                          palette.isDark
                              ? palette.surfaceContainerHigh.withValues(alpha: 0.2)
                              : const Color(0xFFEEEEEE),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        categoryIcon(categoryKey),
                        size: 48,
                        color: palette.primaryContainer.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: palette.isDark
                          ? palette.surface.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onClose,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(Icons.close, color: palette.title, size: 22),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            cardColor,
                            cardColor.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_outlined, color: palette.primaryContainer, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'EMERGENCY CONTACT',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: palette.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: palette.title,
                        ),
                      ),
                      if (organization != null && organization.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          organization,
                          style: GoogleFonts.manrope(fontSize: 16, color: palette.body),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _phoneDetailRow(
                        palette: palette,
                        label: 'Main Office',
                        phone: primaryPhone,
                        fill: rowFill,
                        border: rowBorder,
                        iconBg: palette.primaryContainer,
                        iconColor: Colors.white,
                        onCopy: onCopy,
                        showCopy: true,
                      ),
                      if (hasAlt) ...[
                        const SizedBox(height: 12),
                        _phoneDetailRow(
                          palette: palette,
                          label: 'Alternate line',
                          phone: secondaryPhone,
                          fill: rowFill.withValues(alpha: palette.isDark ? 0.6 : 1),
                          border: rowBorder,
                          iconBg: palette.isDark
                              ? palette.surfaceContainerHighest
                              : const Color(0xFFE8E8E8),
                          iconColor: palette.secondary,
                          onCopy: onCallAlternate ?? () {},
                          showCopy: false,
                          trailingIcon: Icons.call,
                          onTrailing: onCallAlternate,
                        ),
                      ],
                      if (hasAlt || (notes != null && notes.isNotEmpty)) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: palette.muted),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                notes != null && notes.isNotEmpty
                                    ? notes
                                    : 'Call uses the main number first. Use the button below to dial the alternate line.',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: palette.muted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: onCallPrimary,
                          icon: const Icon(Icons.phone_forwarded, size: 20),
                          label: Text(
                            'CALL PRIMARY NOW',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.primaryContainer,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(radiusControl),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onCopy,
                              icon: const Icon(Icons.content_copy, size: 18),
                              label: Text(
                                'COPY',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: palette.primaryContainer,
                                side: BorderSide(
                                  color: palette.primaryContainer.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                minimumSize: const Size(0, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(radiusControl),
                                ),
                              ),
                            ),
                          ),
                          if (hasAlt && onCallAlternate != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: onCallAlternate,
                                icon: const Icon(Icons.alt_route, size: 18),
                                label: Text(
                                  'ALTERNATE',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: palette.title,
                                  side: BorderSide(
                                    color: palette.isDark
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : const Color(0xFFE0E0E0),
                                    width: 1.5,
                                  ),
                                  backgroundColor: palette.isDark
                                      ? palette.surfaceContainerHighest
                                      : const Color(0xFFF3F3F3),
                                  minimumSize: const Size(0, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(radiusControl),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _phoneDetailRow({
    required DashboardPalette palette,
    required String label,
    required String phone,
    required Color fill,
    required Color border,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onCopy,
    required bool showCopy,
    IconData trailingIcon = Icons.content_copy,
    VoidCallback? onTrailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              trailingIcon == Icons.call ? Icons.call : Icons.call,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.onSurfaceVariant,
                  ),
                ),
                Text(
                  phone,
                  style: GoogleFonts.manrope(
                    fontSize: trailingIcon == Icons.call ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onTrailing ?? onCopy,
            icon: Icon(trailingIcon, color: showCopy ? palette.primary : palette.secondary),
          ),
        ],
      ),
    );
  }
}
