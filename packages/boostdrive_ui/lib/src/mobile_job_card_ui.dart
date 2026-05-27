import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_palette.dart';
import 'dashboard_typography.dart';
import 'mobile_customer_ui.dart';

/// Stitch Kinetic Precision job card screens (customer, provider, dialogs, parts sheet).
class MobileJobCardUi {
  MobileJobCardUi._();

  static const Color kineticOrange = Color(0xFFFF6600);
  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = 24;
  static const double radiusControl = 12;

  static String statusLabel(String status, {required bool isProvider}) {
    switch (status.toLowerCase()) {
      case 'quoted':
        return isProvider ? 'IN REVIEW' : 'AWAITING CLIENT RESPONSE';
      case 'accepted':
        return 'ACCEPTED';
      case 'declined':
        return 'DECLINED';
      case 'cancelled':
        return 'CANCELLED';
      case 'active':
        return 'ACTIVE';
      case 'in_progress':
        return 'IN PROGRESS';
      case 'completed':
        return 'COMPLETED';
      default:
        return 'SUBMITTED';
    }
  }

  static PreferredSizeWidget listAppBar({
    required BuildContext context,
    required String title,
    bool showBack = true,
    List<Widget>? actions,
  }) {
    final palette = DashboardPalette.of(context);
    final onColoredHeader = !palette.isDark;
    final mergedActions = actions ?? MobileCustomerUi.appBarActions(onColoredHeader: onColoredHeader);

    if (palette.isDark) {
      return AppBar(
        backgroundColor: palette.background.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        foregroundColor: palette.onBackground,
        leading: showBack
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: palette.onBackground),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        title: Text(
          title,
          style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 20),
        ),
        actions: mergedActions,
      );
    }

    return AppBar(
      backgroundColor: kineticOrange,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      centerTitle: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.maybePop(context),
            )
          : null,
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

  static Widget listHeader({
    required DashboardPalette palette,
    required String title,
    required int totalCount,
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: DashboardTypography.headlineLg(palette).copyWith(fontSize: 28, height: 36 / 28),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: DashboardTypography.bodyMd(palette),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '$totalCount Total',
              style: DashboardTypography.labelMd(palette),
            ),
          ],
        ),
      ],
    );
  }

  static Widget providerStatsRow({
    required DashboardPalette palette,
    required int total,
    required int submitted,
    required int quoted,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _statChip(palette, label: 'All Jobs', count: total, selected: true),
          const SizedBox(width: 8),
          _statChip(palette, label: 'Pending', count: submitted),
          const SizedBox(width: 8),
          _statChip(palette, label: 'In Review', count: quoted),
        ],
      ),
    );
  }

  static Widget _statChip(
    DashboardPalette palette, {
    required String label,
    required int count,
    bool selected = false,
  }) {
    final bg = selected ? kineticOrange : palette.surfaceContainerHighest;
    final fg = selected ? Colors.white : palette.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: selected ? null : Border.all(color: palette.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.2) : kineticOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }

  static Widget focusBanner({
    required DashboardPalette palette,
    required String message,
  }) {
    if (palette.isDark) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kineticOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kineticOrange.withValues(alpha: 0.25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: palette.primaryFixedDim, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Action Required',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.05,
                      color: palette.primaryFixedDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: DashboardTypography.bodySm(palette)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF410002), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  static Widget customerTile({
    required DashboardPalette palette,
    required Map<String, dynamic> row,
    required bool isFocused,
    required VoidCallback? onAccept,
    required VoidCallback? onDecline,
    required VoidCallback? onCancel,
  }) {
    final status = (row['status']?.toString() ?? 'submitted').toLowerCase();
    final labor = (row['labor_amount'] as num?)?.toDouble() ?? 0;
    final vehicle = row['vehicle_label']?.toString() ?? 'Vehicle not set';
    final concern = row['concern_summary']?.toString() ?? '';
    final isQuoted = status == 'quoted';
    final isActionable = isQuoted || status == 'submitted';

    final decoration = palette.isDark
        ? BoxDecoration(
            color: palette.surfaceContainer,
            borderRadius: BorderRadius.circular(radiusCard),
            border: Border.all(
              color: isFocused ? palette.primaryFixedDim : Colors.white.withValues(alpha: 0.1),
              width: isFocused ? 2 : 1,
            ),
            boxShadow: isFocused
                ? [BoxShadow(color: palette.primaryFixedDim.withValues(alpha: 0.15), blurRadius: 20)]
                : null,
          )
        : BoxDecoration(
            color: isQuoted && !palette.isDark
                ? Colors.white.withValues(alpha: 0.85)
                : palette.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(radiusCard),
            border: Border.all(
              color: isQuoted ? kineticOrange.withValues(alpha: 0.35) : const Color(0xFFE2E8F0),
              width: isQuoted ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle, style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 18)),
                  ],
                ),
              ),
              _statusChip(palette, statusLabel(status, isProvider: false), status: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _infoCell(
                  palette,
                  label: 'Concern',
                  value: concern.isEmpty ? '—' : concern,
                  multiline: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _infoCell(
                  palette,
                  label: 'Est. Labor',
                  value: 'N\$${labor.toStringAsFixed(2)}',
                  highlight: isQuoted,
                ),
              ),
            ],
          ),
          if (isQuoted) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAccept,
                style: FilledButton.styleFrom(
                  backgroundColor: kineticOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'VIEW & APPROVE ESTIMATE',
                      style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.04),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: palette.onBackground,
                      side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                    ),
                    child: Text('DECLINE', style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(onPressed: onCancel, child: const Text('CANCEL REQUEST')),
                ),
              ],
            ),
          ] else if (status == 'submitted') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onCancel, child: const Text('CANCEL REQUEST')),
            ),
          ],
          if (!isActionable) const SizedBox(height: 4),
        ],
      ),
    );
  }

  static Widget providerTile({
    required DashboardPalette palette,
    required Map<String, dynamic> row,
    required VoidCallback? onRespond,
    required VoidCallback? onOpen,
  }) {
    final status = (row['status']?.toString() ?? 'submitted').toLowerCase();
    final vehicle = row['vehicle_label']?.toString() ?? 'Vehicle not set';
    final concern = row['concern_summary']?.toString() ?? '';
    final labor = (row['labor_amount'] as num?)?.toDouble() ?? 0;
    final id = row['id']?.toString() ?? '';
    final shortId = id.length > 4 ? '#${id.substring(id.length - 4)}' : (id.isEmpty ? '' : '#$id');

    return Container(
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: palette.isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0)),
        boxShadow: palette.isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel(status, isProvider: true),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.08,
                          color: status == 'submitted' ? kineticOrange : palette.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(vehicle, style: DashboardTypography.headlineMd(palette).copyWith(fontSize: 20)),
                    ],
                  ),
                ),
                if (shortId.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: kineticOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'ID: $shortId',
                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w600, color: kineticOrange),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _infoCell(
                    palette,
                    label: 'Concern',
                    value: concern.isEmpty ? '—' : concern,
                    multiline: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _infoCell(
                    palette,
                    label: 'Est. Labor',
                    value: 'N\$${labor.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status == 'submitted')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRespond,
                  style: FilledButton.styleFrom(
                    backgroundColor: kineticOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                  ),
                  child: Text(
                    'RESPOND WITH PRICE',
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.06),
                  ),
                ),
              )
            else if (status == 'quoted')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: palette.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                  ),
                  child: Text(
                    'WAITING FOR CLIENT',
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.06),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onOpen,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kineticOrange,
                    side: const BorderSide(color: kineticOrange, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                  ),
                  child: Text(
                    'OPEN',
                    style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.06),
                  ),
                ),
              ),
            if (status == 'quoted') ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: onOpen, child: const Text('OPEN')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _infoCell(
    DashboardPalette palette, {
    required String label,
    required String value,
    bool multiline = false,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surfaceContainerLow : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(radiusControl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.06,
              color: palette.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: multiline ? 4 : 2,
            overflow: TextOverflow.ellipsis,
            style: DashboardTypography.bodyMd(palette).copyWith(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w400,
              color: highlight ? palette.primaryFixedDim : palette.onBackground,
              height: multiline ? 1.35 : 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _statusChip(DashboardPalette palette, String label, {required String status}) {
    Color bg;
    Color fg;
    switch (status) {
      case 'quoted':
        bg = kineticOrange.withValues(alpha: 0.12);
        fg = kineticOrange;
        break;
      case 'accepted':
        bg = palette.successSurface;
        fg = palette.success;
        break;
      case 'declined':
      case 'cancelled':
        bg = palette.isDark ? const Color(0xFF3C2020) : const Color(0xFFFEE2E2);
        fg = palette.error;
        break;
      default:
        bg = palette.surfaceContainerHighest;
        fg = palette.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.04, color: fg),
      ),
    );
  }

  static Widget newJobCardFab({required VoidCallback onPressed}) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: kineticOrange,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.add),
      label: Text(
        'NEW JOB CARD',
        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.02),
      ),
    );
  }

  static Widget themedTextField({
    required DashboardPalette palette,
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: palette.isDark ? palette.onSurfaceVariant : const Color(0xFF334155),
            ),
          ),
        ),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboard,
          style: GoogleFonts.manrope(fontSize: 16, color: palette.onBackground),
          decoration: InputDecoration(
            hintText: hint ?? label,
            hintStyle: TextStyle(color: palette.onSurfaceVariant.withValues(alpha: 0.5)),
            prefixIcon: icon != null ? Icon(icon, size: 20, color: palette.onSurfaceVariant) : null,
            filled: true,
            fillColor: palette.isDark ? palette.surfaceContainerLowest : const Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(
              horizontal: icon != null ? 12 : 16,
              vertical: maxLines > 1 ? 14 : 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusControl),
              borderSide: BorderSide(color: palette.surfaceContainerHighest),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(radiusControl),
              borderSide: const BorderSide(color: kineticOrange, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  static Widget dialogShell({
    required DashboardPalette palette,
    required String title,
    String? subtitle,
    required List<Widget> children,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: palette.isDark ? palette.surfaceContainerLow : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DashboardTypography.headlineMd(palette)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: DashboardTypography.bodySm(palette)),
          ],
        ],
      ),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
      actions: actions,
    );
  }

  static Widget cancelTextButton({required VoidCallback onPressed, required DashboardPalette palette}) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        'CANCEL',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.w700,
          color: palette.isDark ? palette.onSurfaceVariant : const Color(0xFF64748B),
        ),
      ),
    );
  }

  static Widget primaryDialogButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: kineticOrange,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label, style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
    );
  }
}
