import 'package:flutter/material.dart';

import '../dashboard_palette.dart';
import 'customer_garage_ui.dart';

/// Shared form chrome for add/edit vehicle and log service dialogs (Kinetic Precision).
class CustomerGarageFormFields {
  CustomerGarageFormFields._();

  static Widget formHeader(BuildContext context, String title) {
    return CustomerGarageUi.sectionLabel(DashboardPalette.of(context), title);
  }

  static Widget textField(
    BuildContext context,
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    final palette = DashboardPalette.of(context);
    return CustomerGarageUi.textField(
      palette: palette,
      controller: controller,
      label: label,
      icon: icon,
      hint: hint,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  static Widget dropdown(
    BuildContext context,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return CustomerGarageUi.dropdown(
      palette: DashboardPalette.of(context),
      label: label,
      value: value,
      items: items,
      onChanged: onChanged,
    );
  }

  static Widget datePickerTile(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onDateSelected,
  ) {
    return CustomerGarageUi.datePickerTile(
      context: context,
      palette: DashboardPalette.of(context),
      label: label,
      selectedDate: selectedDate,
      onDateSelected: onDateSelected,
    );
  }

  static ButtonStyle dialogButtonStyle(BuildContext context) {
    final palette = DashboardPalette.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: palette.title,
      backgroundColor: palette.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
        side: BorderSide(color: palette.outlineVariant.withValues(alpha: 0.35)),
      ),
    );
  }

  static Widget infoRow(BuildContext context, String label, String value) {
    final palette = DashboardPalette.of(context);
    return CustomerGarageUi.detailMetricRow(
      palette: palette,
      icon: Icons.info_outline,
      iconBg: palette.surfaceContainer,
      iconColor: palette.primaryContainer,
      label: label,
      value: value,
    );
  }
}
