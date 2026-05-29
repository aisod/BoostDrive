import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Register a logistics fleet vehicle (type = logistics) for BaTLorriH.
class AddFleetVehicleDialog extends ConsumerStatefulWidget {
  final String ownerId;

  const AddFleetVehicleDialog({super.key, required this.ownerId});

  @override
  ConsumerState<AddFleetVehicleDialog> createState() => _AddFleetVehicleDialogState();
}

class _AddFleetVehicleDialogState extends ConsumerState<AddFleetVehicleDialog> {
  final _make = TextEditingController();
  final _model = TextEditingController();
  final _plate = TextEditingController();
  final _year = TextEditingController(text: '${DateTime.now().year}');
  bool _saving = false;

  @override
  void dispose() {
    _make.dispose();
    _model.dispose();
    _plate.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_make.text.trim().isEmpty || _model.text.trim().isEmpty || _plate.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Make, model, and plate are required.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final vehicle = Vehicle(
        id: '',
        ownerId: widget.ownerId,
        make: _make.text.trim(),
        model: _model.text.trim(),
        year: int.tryParse(_year.text.trim()) ?? DateTime.now().year,
        plateNumber: _plate.text.trim().toUpperCase(),
        type: 'logistics',
        createdAt: DateTime.now(),
        healthStatus: 'Healthy',
        fuelLevel: '100%',
      );
      await ref.read(vehicleServiceProvider).addVehicle(vehicle);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not add vehicle: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BoostDriveTheme.surfaceDark,
      title: const Text('Add fleet vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_make, 'Make', 'e.g. Toyota'),
            const SizedBox(height: 12),
            _field(_model, 'Model', 'e.g. Hilux'),
            const SizedBox(height: 12),
            _field(_plate, 'Plate number', 'N12345W'),
            const SizedBox(height: 12),
            _field(_year, 'Year', '2024', keyboardType: TextInputType.number),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, String hint, {TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: BoostDriveTheme.textDim),
        hintStyle: TextStyle(color: BoostDriveTheme.textDim.withValues(alpha: 0.5)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: BoostDriveTheme.primaryColor)),
      ),
    );
  }
}
