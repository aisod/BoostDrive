import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';
import 'dashboard_theme_toggle.dart';
import 'dashboard_typography.dart';
import 'theme.dart';

/// Stitch-aligned UI helpers for [ProfileSettingsPage] provider flows (view + edit).
class ProviderProfileUi {
  ProviderProfileUi._();

  static LinearGradient heroGradient(DashboardPalette palette) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          palette.primaryContainer,
          palette.isDark ? palette.primaryBright : const Color(0xFFFF9800),
        ],
      );

  static BoxDecoration heroBannerDecoration(DashboardPalette palette) => BoxDecoration(
        gradient: heroGradient(palette),
      );

  static List<BoxShadow> premiumShadow(DashboardPalette palette) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.10),
          blurRadius: palette.isDark ? 20 : 12,
          offset: const Offset(0, 4),
        ),
      ];

  static Widget sectionCard({
    required DashboardPalette palette,
    required Widget child,
    IconData? icon,
    String? title,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Color? backgroundColor,
    bool accentTint = false,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ??
            (accentTint
                ? palette.primary.withValues(alpha: palette.isDark ? 0.08 : 0.05)
                : palette.surfaceContainerLowest),
        borderRadius: BorderRadius.circular(palette.radiusDefault),
        border: Border.all(
          color: accentTint
              ? palette.primary.withValues(alpha: 0.2)
              : palette.outlineVariant.withValues(alpha: palette.isDark ? 0.15 : 0.35),
        ),
        boxShadow: palette.isDark ? null : premiumShadow(palette),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            sectionHeader(palette: palette, title: title, icon: icon ?? Icons.article_outlined),
            const SizedBox(height: 20),
          ],
          child,
        ],
      ),
    );
  }

  static Widget sectionHeader({
    required DashboardPalette palette,
    required String title,
    required IconData icon,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: palette.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title.toUpperCase(),
            style: DashboardTypography.headlineMd(palette).copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  static Widget sectionSubtitle(DashboardPalette palette, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: DashboardTypography.bodySm(palette),
      ),
    );
  }

  static Widget fieldLabel(DashboardPalette palette, String text) {
    return Text(
      text,
      style: DashboardTypography.labelMd(palette).copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }

  static InputDecoration inputDecoration(
    DashboardPalette palette, {
    String? hint,
    bool readOnly = false,
  }) {
    return InputDecoration(
      hintText: hint ?? '',
      hintStyle: DashboardTypography.bodySm(palette).copyWith(color: palette.muted),
      filled: true,
      fillColor: readOnly ? palette.surfaceContainerLow : palette.surfaceContainerLowest,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.primaryContainer, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.25)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static TextStyle fieldTextStyle(DashboardPalette palette, {bool readOnly = false}) {
    return GoogleFonts.manrope(
      fontSize: 14,
      color: palette.onBackground,
      fontWeight: readOnly ? FontWeight.w600 : FontWeight.w500,
    );
  }

  /// Read-only label/value pair for bento view layout.
  static Widget readOnlyField(DashboardPalette palette, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: DashboardTypography.sectionLabel(palette).copyWith(
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value.isEmpty ? '—' : value,
          style: DashboardTypography.bodyLg(palette).copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  static Widget verifiedChip(DashboardPalette palette, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(palette.radiusPill),
        border: Border.all(color: palette.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_outlined, size: 16, color: palette.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: DashboardTypography.labelMd(palette).copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static Widget identityName(DashboardPalette palette, String name, {bool verified = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: palette.onBackground,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (verified) ...[
          const SizedBox(width: 8),
          Icon(Icons.verified, color: palette.primary, size: 26),
        ],
      ],
    );
  }

  static PreferredSizeWidget providerAppBar({
    required BuildContext context,
    required String title,
    required VoidCallback onBack,
    required DashboardPalette palette,
    Widget? action,
    bool showThemeToggle = true,
  }) {
    final trailing = <Widget>[
      if (showThemeToggle)
        const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Center(
            child: DashboardThemeToggle(onColoredHeader: true, compact: true),
          ),
        ),
      if (action != null) action,
    ];

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      forceMaterialTransparency: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: onBack,
      ),
      title: Text(
        title,
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: trailing.isEmpty ? null : trailing,
    );
  }

  static Widget editProfilePillButton({
    required VoidCallback onPressed,
    required String label,
    DashboardPalette? palette,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: palette?.primary ?? BoostDriveTheme.primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.12),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  static Widget exitEditTextButton({required VoidCallback onPressed}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'Exit Edit Mode',
        style: GoogleFonts.manrope(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }

  static Widget providerStepper({
    required DashboardPalette palette,
    required int currentStep,
    required List<String> stepTitles,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surfaceContainerLow,
        borderRadius: BorderRadius.circular(palette.radiusDefault),
        border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: List.generate(stepTitles.length, (index) {
          final active = index == currentStep;
          final done = index < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active || done
                              ? palette.primaryContainer
                              : palette.surfaceContainerHighest,
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: palette.primary.withValues(alpha: 0.25),
                                    blurRadius: 12,
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: done
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.manrope(
                                  color: active || done ? Colors.white : palette.muted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        stepTitles[index],
                        textAlign: TextAlign.center,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active ? palette.primary : palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index != stepTitles.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 28),
                      color: done ? palette.primary : palette.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  static Widget statRow(DashboardPalette palette, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: DashboardTypography.bodySm(palette))),
          Text(
            value,
            style: DashboardTypography.labelLg(palette).copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  static Widget specializationChip(DashboardPalette palette, String label, {bool selected = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? palette.primary.withValues(alpha: 0.08)
            : palette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(selected ? 8 : 999),
        border: Border.all(
          color: selected ? palette.primary.withValues(alpha: 0.25) : palette.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: DashboardTypography.bodySm(palette).copyWith(
          color: selected ? palette.primary : palette.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static Widget brandChip(DashboardPalette palette, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: palette.primary),
          const SizedBox(width: 6),
          Text(label, style: DashboardTypography.labelMd(palette)),
        ],
      ),
    );
  }

  static Widget iconFactTile({
    required DashboardPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: palette.primary.withValues(alpha: 0.1),
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
              Text(subtitle, style: DashboardTypography.bodySm(palette)),
            ],
          ),
        ),
      ],
    );
  }

  static ButtonStyle primaryButtonStyle(DashboardPalette palette) => ElevatedButton.styleFrom(
        minimumSize: const Size(0, 48),
        backgroundColor: palette.primaryContainer,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: palette.isDark ? 0 : 2,
      );

  static ButtonStyle outlinedButtonStyle(DashboardPalette palette) => OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        foregroundColor: palette.onBackground,
      );

  /// Glass-style inner panel (documents vault, nested forms).
  static BoxDecoration glassCardDecoration(DashboardPalette palette) => BoxDecoration(
        color: palette.isDark
            ? palette.surfaceContainer.withValues(alpha: 0.92)
            : palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(palette.radiusDefault),
        border: Border.all(
          color: palette.outlineVariant.withValues(alpha: palette.isDark ? 0.12 : 0.35),
        ),
        boxShadow: palette.isDark ? null : premiumShadow(palette),
      );

  static Widget vaultProgressBadge(
    DashboardPalette palette, {
    required int completed,
    required int total,
  }) {
    final pct = total == 0 ? 0 : ((completed / total) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(palette.radiusPill),
        border: Border.all(color: palette.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$completed / $total · $pct%',
        style: DashboardTypography.labelMd(palette).copyWith(
          color: palette.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  static Widget choiceChip({
    required DashboardPalette palette,
    required String label,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(selected ? 8 : 999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? palette.primary.withValues(alpha: 0.12)
                : palette.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(selected ? 8 : 999),
            border: Border.all(
              color: selected
                  ? palette.primary.withValues(alpha: 0.35)
                  : palette.outlineVariant.withValues(alpha: 0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: selected ? palette.primary : palette.muted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: DashboardTypography.bodySm(palette).copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? palette.primary : palette.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget subsectionHeading(DashboardPalette palette, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: DashboardTypography.labelLg(palette)),
    );
  }

  static Widget safetyPanel({
    required DashboardPalette palette,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.error.withValues(alpha: palette.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(palette.radiusDefault),
        border: Border.all(color: palette.error.withValues(alpha: 0.25)),
      ),
      child: child,
    );
  }

  static Widget controlCenterShell({
    required DashboardPalette palette,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(palette.radiusDefault),
        border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: palette.isDark ? null : premiumShadow(palette),
      ),
      child: child,
    );
  }
}
