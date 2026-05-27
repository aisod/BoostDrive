import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'dashboard_theme_toggle.dart';

/// Stitch mobile customer/seller UI primitives (Kinetic Precision).
class MobileCustomerUi {
  MobileCustomerUi._();

  static const double marginMobile = 20;
  static const double radiusCard = 24;
  static const double radiusControl = 12;

  /// Light/dark pill for orange or neutral app bars.
  static List<Widget> appBarActions({
    List<Widget>? trailing,
    bool onColoredHeader = true,
  }) {
    return [
      DashboardThemeToggle(compact: true, onColoredHeader: onColoredHeader),
      ...?trailing,
    ];
  }

  /// Orange top bar: BOOSTDRIVE / section titles (includes theme toggle).
  ///
  /// Do not wrap [AppBar] in [Consumer] here — that breaks scaffold app-bar disposal
  /// (`_dependents.isEmpty`). Theme toggle is a [ConsumerWidget] child of [actions].
  static PreferredSizeWidget topAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool showMenuIcon = false,
    bool showThemeToggle = true,
  }) {
    final mergedActions = showThemeToggle
        ? appBarActions(trailing: actions, onColoredHeader: true)
        : actions;
    return AppBar(
      backgroundColor: const Color(0xFFFF6600),
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      centerTitle: false,
      leading: leading ??
          (showMenuIcon
              ? IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                )
              : null),
      title: Text(
        title.toUpperCase(),
        style: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      actions: mergedActions,
    );
  }

  static BoxDecoration surfaceCard(DashboardPalette p, {bool elevated = true}) {
    return BoxDecoration(
      color: p.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(radiusCard),
      border: Border.all(
        color: p.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFE2E8F0),
      ),
      boxShadow: elevated && !p.isDark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }

  /// Greeting row: avatar, welcome, chat + notifications.
  static Widget greetingCard({
    required DashboardPalette palette,
    required String fullName,
    String? profileImageUrl,
    required Widget notificationsButton,
    required Widget messagesButton,
    String memberLabel = 'PREMIUM MEMBER',
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: surfaceCard(palette),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: palette.surfaceContainer,
                backgroundImage:
                    profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : null,
                child: profileImageUrl == null || profileImageUrl.isEmpty
                    ? Icon(Icons.person, color: palette.primary, size: 28)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: palette.surfaceContainerLowest, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberLabel,
                  style: DashboardTypography.labelMd(palette).copyWith(
                    letterSpacing: 1.2,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Welcome back, $fullName',
                  style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          messagesButton,
          const SizedBox(width: 8),
          notificationsButton,
        ],
      ),
    );
  }

  static Widget iconActionButton({
    required DashboardPalette palette,
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
    Color? badgeColor,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: palette.isDark
              ? palette.surfaceContainer.withValues(alpha: 0.6)
              : const Color(0xFFF1F5F9),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 22, color: palette.title),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: badgeColor ?? const Color(0xFFDC2626),
                shape: BoxShape.circle,
                border: Border.all(color: palette.surfaceContainerLowest, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Provider quote banner (existing REVIEW flow).
  static Widget quoteAlertCard({
    required DashboardPalette palette,
    required String laborAmount,
    required int pendingCount,
    required VoidCallback onReview,
  }) {
    final accent = palette.isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
    final bg = palette.isDark
        ? const Color(0xFF312E81).withValues(alpha: 0.35)
        : const Color(0xFFEEF2FF);
    final border = palette.isDark ? const Color(0xFF4338CA) : const Color(0xFFC7D2FE);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.request_quote, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provider Quote Received',
                  style: DashboardTypography.headlineMd(palette).copyWith(
                    fontSize: 17,
                    color: palette.isDark ? Colors.white : const Color(0xFF312E81),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Labor quote: $laborAmount • $pendingCount pending response',
                  style: DashboardTypography.bodySm(palette),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onReview,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                    ),
                    child: Text(
                      'VIEW QUOTE',
                      style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Single-tap SOS promo (navigates to Emergency hub — no extra buttons).
  static Widget sosPromoCard({
    required DashboardPalette palette,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusCard),
        child: Ink(
          decoration: BoxDecoration(
            color: palette.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(radiusCard),
            border: Border.all(color: const Color(0xFFFF6600), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6600).withValues(alpha: palette.isDark ? 0.15 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sos, color: palette.primaryBright, size: 36),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Emergency & SOS',
                        style: DashboardTypography.headlineMd(palette).copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: palette.primary),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Request towing or a mobile mechanic when you need help.',
                  style: DashboardTypography.bodySm(palette),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget jobCardPromoCard({
    required DashboardPalette palette,
    required VoidCallback onOpen,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: surfaceCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.assignment_outlined, color: palette.primary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Customer Job Card & Diagnostics',
                  style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 17),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Create your job card request and receive required part recommendations from your provider.',
            style: DashboardTypography.bodySm(palette),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: onOpen,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6600),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
              ),
              child: Text(
                'OPEN CUSTOMER JOB CARD',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Marketplace / filter category pill.
  static Widget categoryPill({
    required DashboardPalette palette,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? const Color(0xFFFF6600) : palette.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: selected
                  ? null
                  : Border.all(
                      color: palette.outlineVariant.withValues(alpha: 0.35),
                    ),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.03,
                color: selected ? Colors.white : palette.title,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shop header logo tile (B / S badge).
  static Widget shopLogoBadge({
    required DashboardPalette palette,
    required String letter,
    bool isSeller = false,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: isSeller ? const Color(0xFFFF6600) : const Color(0xFF2563EB),
        ),
      ),
    );
  }

  /// Glass-style bottom navigation shell.
  static Widget glassBottomNav({
    required Widget child,
    required DashboardPalette palette,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (palette.isDark ? palette.surface : palette.surfaceContainerLowest)
            .withValues(alpha: 0.88),
        border: Border(
          top: BorderSide(
            color: palette.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE2E8F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? 0.35 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: child,
    );
  }
}
