import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'mobile_customer_ui.dart';

/// Kinetic Precision UI for mobile customer Profile Settings (Stitch exports).
class CustomerProfileSettingsUi {
  CustomerProfileSettingsUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;
  static const double mobileBreakpoint = 900;

  /// Mobile/narrow layout (native app or mobile web viewport).
  static bool useMobileLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

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

  /// Frosted top bar: back + title + theme toggle (+ optional save when editing).
  static PreferredSizeWidget glassAppBar({
    required BuildContext context,
    required DashboardPalette palette,
    required String title,
    List<Widget>? trailing,
  }) {
    final barBg = palette.isDark
        ? palette.background.withValues(alpha: 0.94)
        : palette.surfaceContainerLowest.withValues(alpha: 0.85);
    final accent = palette.primaryContainer;
    final titleColor = palette.isDark ? palette.primaryContainer : palette.primaryContainer;

    return AppBar(
      backgroundColor: barBg,
      foregroundColor: accent,
      iconTheme: IconThemeData(color: accent),
      actionsIconTheme: IconThemeData(color: accent),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: Navigator.canPop(context)
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: accent),
              onPressed: () => Navigator.maybePop(context),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          : null,
      title: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: titleColor,
          letterSpacing: -0.3,
        ),
      ),
      actions: MobileCustomerUi.appBarActions(
        onColoredHeader: false,
        trailing: trailing,
      ),
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

  /// Centered avatar, display name, member-since line.
  static Widget profileSummaryCard({
    required DashboardPalette palette,
    required String displayName,
    required String memberSinceLabel,
    required Widget avatar,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: premiumCard(palette),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -48,
            right: -48,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.primaryContainer.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              avatar,
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Text(
                  displayName,
                  style: GoogleFonts.manrope(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: palette.title,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: Text(
                  memberSinceLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: palette.secondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget cameraFab({
    required DashboardPalette palette,
    required bool isUploading,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.primaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: palette.surfaceContainerLowest, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.photo_camera, color: Colors.white, size: 18),
    );
  }

  static Widget personalInformationCard({
    required DashboardPalette palette,
    required bool isEditing,
    required VoidCallback onToggleEdit,
    required List<Widget> fieldTiles,
    Widget? editFooter,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: premiumCard(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERSONAL INFORMATION',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  color: palette.title.withValues(alpha: 0.7),
                ),
              ),
              TextButton.icon(
                onPressed: onToggleEdit,
                icon: Icon(
                  isEditing ? Icons.close : Icons.edit,
                  size: 16,
                  color: palette.primaryContainer,
                ),
                label: Text(
                  isEditing ? 'Cancel' : 'Edit',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryContainer,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...fieldTiles,
          if (editFooter != null) ...[
            const SizedBox(height: 16),
            editFooter,
          ],
        ],
      ),
    );
  }

  static Widget infoFieldTile({
    required DashboardPalette palette,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = false,
    bool showVerified = false,
  }) {
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: fieldSurface(palette),
          borderRadius: BorderRadius.circular(radiusControl),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: palette.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isEditable && controller != null)
                    TextField(
                      controller: controller,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )
                  else
                    Text(
                      value.isEmpty ? 'Not set' : value,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.title,
                      ),
                    ),
                ],
              ),
            ),
            if (showVerified)
              Icon(
                Icons.verified,
                size: 22,
                color: palette.primaryContainer.withValues(alpha: 0.45),
              ),
          ],
        ),
      ),
    );
  }

  static Widget saveCancelRow({
    required DashboardPalette palette,
    required VoidCallback onCancel,
    required VoidCallback onSave,
    required bool isSaving,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 48),
              side: BorderSide(
                color: palette.primaryContainer.withValues(alpha: 0.35),
              ),
              foregroundColor: palette.title,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusControl),
              ),
            ),
            child: Text(
              'Cancel',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 48),
              backgroundColor: palette.primaryContainer,
              foregroundColor: palette.isDark ? const Color(0xFF1A1A1A) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusControl),
              ),
            ),
            child: isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: palette.isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  static Widget safetyCard({
    required DashboardPalette palette,
    required int activeContactCount,
    required List<({String name, String initials})> contactChips,
    required VoidCallback onManage,
  }) {
    final subtitle = activeContactCount == 0
        ? 'No emergency contacts yet'
        : activeContactCount == 1
            ? '1 emergency contact active'
            : '$activeContactCount emergency contacts active';

    final edgeBorder = palette.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardSurface(palette),
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border(
          left: BorderSide(color: palette.error.withValues(alpha: 0.5), width: 4),
          top: BorderSide(color: edgeBorder),
          right: BorderSide(color: edgeBorder),
          bottom: BorderSide(color: edgeBorder),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.error.withValues(alpha: palette.isDark ? 0.18 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield, color: palette.error, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety & SOS',
                      style: DashboardTypography.labelLg(palette),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: DashboardTypography.bodySm(palette),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onManage,
                child: Text(
                  'Manage',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
          if (contactChips.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: contactChips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final chip = contactChips[i];
                  return _contactChip(palette, chip.initials, chip.name);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _contactChip(DashboardPalette palette, String initials, String name) {
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: fieldSurface(palette),
        borderRadius: BorderRadius.circular(radiusPill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Text(
              initials,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: palette.title,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.title,
            ),
          ),
        ],
      ),
    );
  }

  static const double radiusPill = 999;

  static String contactInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w.toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Widget hubOperationsCard({
    required BuildContext context,
    required DashboardPalette palette,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: premiumCard(palette),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
            onSurface: palette.title,
            onSurfaceVariant: palette.muted,
          ),
          listTileTheme: ListTileThemeData(
            iconColor: palette.tertiary,
            textColor: palette.title,
            titleTextStyle: DashboardTypography.labelLg(palette),
          ),
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: palette.secondary,
            collapsedIconColor: palette.secondary,
            textColor: palette.title,
            collapsedTextColor: palette.title,
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          leading: Icon(Icons.hub_outlined, color: palette.tertiary, size: 24),
          title: Text(
            'Hub & Operations',
            style: DashboardTypography.labelLg(palette),
          ),
          children: children,
        ),
      ),
    );
  }

  static Widget hubListRow({
    required DashboardPalette palette,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusControl),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.primaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: DashboardTypography.labelLg(palette).copyWith(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: DashboardTypography.bodySm(palette)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: palette.muted),
            ],
          ),
        ),
      ),
    );
  }

  static Widget accountActions({
    required DashboardPalette palette,
    required VoidCallback onLogout,
    required VoidCallback onDeleteAccount,
  }) {
    final borderColor = palette.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onLogout,
            icon: Icon(Icons.logout, color: palette.secondary, size: 20),
            label: Text(
              'Log Out',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.title,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: palette.isDark ? cardSurface(palette) : palette.surfaceContainerLowest,
              side: BorderSide(color: borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusControl),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: onDeleteAccount,
            icon: Icon(Icons.delete_forever, color: palette.error, size: 20),
            label: Text(
              'Delete Account',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: palette.error,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: palette.isDark ? cardSurface(palette) : Colors.transparent,
              side: BorderSide(color: palette.error.withValues(alpha: 0.25)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusControl),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget versionFooter(DashboardPalette palette, {String version = 'BoostDrive Version 2.4.1 (1209)'}) {
    return Text(
      version,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: palette.muted,
      ),
      textAlign: TextAlign.center,
    );
  }
}
