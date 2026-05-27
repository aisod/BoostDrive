import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:boostdrive_core/boostdrive_core.dart';

import '../dashboard_palette.dart';
import '../dashboard_typography.dart';
import '../mobile_customer_ui.dart';

/// Kinetic Precision garage UI (Stitch mobile garage + dialogs).
class CustomerGarageUi {
  CustomerGarageUi._();

  static const double marginMobile = MobileCustomerUi.marginMobile;
  static const double radiusCard = MobileCustomerUi.radiusCard;
  static const double radiusControl = MobileCustomerUi.radiusControl;
  static const double radiusSheetTop = 32;

  /// Bottom sheet shell for add vehicle, log service, service details.
  static Future<T?> showSheet<T>({
    required BuildContext context,
    required String title,
    required Widget Function(BuildContext context, ScrollController scrollController) bodyBuilder,
    Widget? footer,
    List<Widget>? trailing,
    double initialChildSize = 0.92,
  }) {
    final palette = DashboardPalette.of(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: palette.isDark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.4),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: palette.surfaceContainerLowest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusSheetTop)),
                border: Border(
                  top: BorderSide(
                    color: palette.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: palette.isDark ? 0.4 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.onSurfaceVariant.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(marginMobile, 12, marginMobile, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: palette.title,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (trailing != null) ...trailing,
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          style: IconButton.styleFrom(
                            backgroundColor: palette.surfaceContainerHighest.withValues(alpha: 0.5),
                          ),
                          icon: Icon(Icons.close, color: palette.onSurfaceVariant, size: 22),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: bodyBuilder(context, scrollController),
                  ),
                  if (footer != null) footer,
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget sectionLabel(DashboardPalette palette, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: palette.onSurfaceVariant,
        ),
      ),
    );
  }

  static InputDecoration _fieldDecoration(DashboardPalette palette, {IconData? icon, String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: palette.muted, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: palette.primary.withValues(alpha: 0.55), size: 20)
          : null,
      filled: true,
      fillColor: palette.isDark ? palette.surfaceContainerLow : palette.surfaceDim,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusControl),
        borderSide: BorderSide(color: palette.primaryContainer, width: 1.5),
      ),
    );
  }

  static Widget labeledField({
    required DashboardPalette palette,
    required String label,
    required Widget field,
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
              fontWeight: FontWeight.w600,
              color: palette.onSurfaceVariant,
            ),
          ),
        ),
        field,
      ],
    );
  }

  static Widget textField({
    required DashboardPalette palette,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return labeledField(
      palette: palette,
      label: label,
      field: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.manrope(fontSize: 15, color: palette.title),
        decoration: _fieldDecoration(palette, icon: icon, hint: hint),
      ),
    );
  }

  static Widget dropdown({
    required DashboardPalette palette,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return labeledField(
      palette: palette,
      label: label,
      field: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: palette.isDark ? palette.surfaceContainerLow : palette.surfaceDim,
          borderRadius: BorderRadius.circular(radiusControl),
          border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.25)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: palette.surfaceContainerLowest,
            style: GoogleFonts.manrope(fontSize: 15, color: palette.title),
            items: items
                .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  static Widget datePickerTile({
    required BuildContext context,
    required DashboardPalette palette,
    required String label,
    required DateTime? selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return labeledField(
      palette: palette,
      label: label,
      field: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radiusControl),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
            );
            if (date != null) onDateSelected(date);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.isDark ? palette.surfaceContainerLow : palette.surfaceDim,
              borderRadius: BorderRadius.circular(radiusControl),
              border: Border.all(color: palette.outlineVariant.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? 'Select Date'
                        : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: GoogleFonts.manrope(fontSize: 15, color: palette.title),
                  ),
                ),
                Icon(Icons.calendar_today, color: palette.primary.withValues(alpha: 0.55), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget sheetFooter({
    required DashboardPalette palette,
    required VoidCallback onCancel,
    required VoidCallback? onPrimary,
    required String primaryLabel,
    bool primaryLoading = false,
    IconData? primaryIcon,
    double primaryFlex = 2,
  }) {
    return Container(
      padding: const EdgeInsets.all(marginMobile),
      decoration: BoxDecoration(
        color: palette.surfaceContainerLowest,
        border: Border(top: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.15))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.onSurfaceVariant,
                  side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.4)),
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'CANCEL',
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: primaryFlex.round() + 1,
              child: FilledButton(
                onPressed: primaryLoading ? null : onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primaryContainer,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 56),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusControl)),
                ),
                child: primaryLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  primaryLabel,
                                  maxLines: 1,
                                  softWrap: false,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                if (primaryIcon != null) ...[
                                  const SizedBox(width: 6),
                                  Icon(primaryIcon, size: 18),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget photoUploadPlaceholder({
    required DashboardPalette palette,
    required VoidCallback onTap,
    String label = 'Tap to upload photos',
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusControl),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: palette.surfaceDim,
              borderRadius: BorderRadius.circular(radiusControl),
              border: Border.all(
                color: palette.outlineVariant.withValues(alpha: 0.35),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: palette.primaryContainer, size: 40),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: palette.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget horizontalThumbGallery({
    required DashboardPalette palette,
    required List<Widget> children,
    double height = 120,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: children,
      ),
    );
  }

  static Widget networkThumb(String url, {double size = 120}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusControl),
        child: Image.network(url, width: size, height: size, fit: BoxFit.cover),
      ),
    );
  }

  static Widget pendingThumb({
    required Uint8List bytes,
    required VoidCallback onRemove,
    double size = 120,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radiusControl),
            child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget uploadReceiptTile({
    required DashboardPalette palette,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radiusControl),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: palette.primaryContainer.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(radiusControl),
              border: Border.all(
                color: palette.primaryContainer,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: palette.primaryContainer, size: 28),
                const SizedBox(height: 6),
                Text(
                  'UPLOAD',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget logServiceHeaderBadge(DashboardPalette palette) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: palette.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.build, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 8),
        Text(
          'NEW ENTRY',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: palette.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  static Widget detailMetricRow({
    required DashboardPalette palette,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: MobileCustomerUi.surfaceCard(palette, elevated: !palette.isDark),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: palette.muted,
              ),
            ),
          ),
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

  static Widget serviceHeroCard({
    required DashboardPalette palette,
    required String serviceName,
    String? subtitle,
    List<String>? imageUrls,
  }) {
    final hasImage = imageUrls != null && imageUrls.isNotEmpty;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radiusCard),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage)
              Image.network(imageUrls!.first, fit: BoxFit.cover)
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      palette.surfaceContainerHigh,
                      palette.isDark ? const Color(0xFF050F16) : const Color(0xFF1A1A1A),
                    ],
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'LOGGED',
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: GoogleFonts.manrope(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.manrope(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget featuredVehicleCard({
    required DashboardPalette palette,
    required Vehicle vehicle,
    required VoidCallback onTap,
  }) {
    final healthy = vehicle.healthStatus.toLowerCase().contains('healthy') ||
        vehicle.healthStatus.toLowerCase().contains('good');
    final healthPct = healthy ? 0.92 : 0.55;
    final nextDue = vehicle.nextServiceDueMileage;
    final kmLeft = nextDue != null ? (nextDue - vehicle.mileage).clamp(0, 999999) : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radiusCard),
        child: Container(
          decoration: MobileCustomerUi.surfaceCard(palette),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (vehicle.imageUrls.isNotEmpty)
                      Image.network(vehicle.imageUrls.first, fit: BoxFit.cover)
                    else
                      ColoredBox(
                        color: palette.surfaceContainer,
                        child: Icon(Icons.directions_car, size: 64, color: palette.muted),
                      ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            palette.surfaceContainerLowest.withValues(alpha: 0.95),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
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
                                '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                                style: GoogleFonts.manrope(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: palette.title,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${vehicle.plateNumber} • ${vehicle.mileage} KM',
                                style: DashboardTypography.bodySm(palette),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'HEALTH',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                                color: palette.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 64,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: healthPct,
                                  minHeight: 6,
                                  backgroundColor: palette.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(palette.primaryContainer),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _statChip(palette, Icons.speed, '${vehicle.mileage} km'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _statChip(palette, Icons.tire_repair, vehicle.tireHealth),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _statChip(
                            palette,
                            Icons.oil_barrel,
                            kmLeft != null ? '$kmLeft km left' : 'Service —',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _statChip(DashboardPalette palette, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: palette.surfaceContainer,
        borderRadius: BorderRadius.circular(radiusControl),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: palette.primaryContainer, size: 20),
          const SizedBox(height: 4),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: palette.title,
            ),
          ),
        ],
      ),
    );
  }

  static Widget garagePageHeader({
    required DashboardPalette palette,
    required int vehicleCount,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Garage',
              style: GoogleFonts.manrope(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: palette.title,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: palette.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: palette.isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                ),
              ),
              child: Text(
                '$vehicleCount ACTIVE',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.primaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Manage your fleet and track precision maintenance cycles.',
          style: DashboardTypography.bodyMd(palette),
        ),
      ],
    );
  }
}
