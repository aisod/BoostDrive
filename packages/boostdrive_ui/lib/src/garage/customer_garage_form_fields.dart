import 'package:flutter/material.dart';
import '../theme.dart';

/// Shared form chrome for add/edit vehicle and log service dialogs (matches web customer dashboard).
class CustomerGarageFormFields {
  CustomerGarageFormFields._();

  static Widget formHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: BoostDriveTheme.primaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static Widget textField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0x22FF6600), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  static Widget dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: BoostDriveTheme.surfaceDark,
              items: items
                  .map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(color: Colors.white, fontSize: 14))))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  static Widget datePickerTile(
    BuildContext context,
    String label,
    DateTime? selectedDate,
    ValueChanged<DateTime> onDateSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 6),
        InkWell(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedDate == null ? 'Select Date' : '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const Icon(Icons.calendar_today, color: Color(0x22FF6600), size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static ButtonStyle dialogButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x22FF6600)),
      ),
    );
  }

  static Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
