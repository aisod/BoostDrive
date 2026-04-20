import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

import '../theme.dart';
import 'customer_garage_form_fields.dart';

class _PendingVehicleImage {
  _PendingVehicleImage(this.file, this.bytes);
  final image_picker.XFile file;
  final Uint8List bytes;
}

/// Same add/edit vehicle flow as the web customer dashboard (full form + photo required for new vehicles).
void showCustomerAddVehicleDialog(BuildContext context, WidgetRef ref, String uid, {Vehicle? vehicle}) {
  final makeController = TextEditingController(text: vehicle?.make);
  final modelController = TextEditingController(text: vehicle?.model);
  final yearController = TextEditingController(text: vehicle?.year.toString() ?? '${DateTime.now().year}');
  final plateController = TextEditingController(text: vehicle?.plateNumber);
  final mileageController = TextEditingController(text: vehicle?.mileage.toString() ?? '0');
  final capacityController = TextEditingController(text: vehicle?.engineCapacity);
  final descriptionController = TextEditingController(text: vehicle?.description);
  final modificationController = TextEditingController(text: vehicle?.modifications);
  final safetyController = TextEditingController(text: vehicle?.safetyTech);
  final towingController = TextEditingController(text: vehicle?.towingCapacity);
  final nextServiceController = TextEditingController(text: vehicle?.nextServiceDueMileage?.toString());
  final oilLifeController = TextEditingController(text: vehicle?.oilLife);
  final brakeFluidController = TextEditingController(text: vehicle?.brakeFluidStatus);
  final activeFaultsController = TextEditingController(text: vehicle?.activeFaults);
  final vinController = TextEditingController(text: vehicle?.vin);
  final efficiencyController = TextEditingController(text: vehicle?.fuelEfficiency);
  final exteriorController = TextEditingController(text: vehicle?.exteriorCondition);

  String tireHealth = vehicle?.tireHealth ?? 'Brand New';
  String serviceHistory = vehicle?.serviceHistoryType ?? 'Full Service History (FSH)';
  String transmission = vehicle?.transmission ?? 'Automatic';
  String fuelType = vehicle?.fuelType ?? 'Petrol';
  String driveType = vehicle?.driveType ?? '4x2';
  String accidentHistory = vehicle?.accidentHistory ?? 'No';
  bool spareKey = vehicle?.spareKey ?? false;
  String interiorMaterial = vehicle?.interiorMaterial ?? 'Cloth';
  DateTime? licenseRenewal = vehicle?.nextLicenseRenewal;
  DateTime? insuranceExpiry = vehicle?.insuranceExpiry;
  DateTime? warrantyExpiry = vehicle?.warrantyExpiry;

  final imagePicker = image_picker.ImagePicker();
  final pendingImages = <_PendingVehicleImage>[];
  bool isSaving = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Row(
            children: [
              Icon(vehicle == null ? Icons.add_road : Icons.edit_road, color: BoostDriveTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  vehicle == null ? 'Add Vehicle to Garage' : 'Edit Vehicle Details',
                  style: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w900, color: Colors.white),
                ),
              ),
              if (isSaving) ...[
                const SizedBox(width: 16),
                const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BoostDriveTheme.primaryColor)),
              ],
            ],
          ),
          content: SizedBox(
            width: min(600, MediaQuery.sizeOf(context).width - 48),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerGarageFormFields.formHeader('VEHICLE PHOTO'),
                  const SizedBox(height: 12),
                  Center(
                    child: Column(
                      children: [
                        if (pendingImages.isNotEmpty || (vehicle?.imageUrls.isNotEmpty ?? false))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: SizedBox(
                              height: 120,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  if (vehicle != null)
                                    ...vehicle!.imageUrls.map(
                                      (url) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(url, height: 120, width: 120, fit: BoxFit.cover),
                                        ),
                                      ),
                                    ),
                                  ...pendingImages.asMap().entries.map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.memory(entry.value.bytes, height: 120, width: 120, fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => setDialogState(() => pendingImages.removeAt(entry.key)),
                                              child: const CircleAvatar(
                                                radius: 12,
                                                backgroundColor: Colors.black54,
                                                child: Icon(Icons.close, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final imgs = await imagePicker.pickMultiImage();
                            if (imgs.isEmpty) return;
                            for (final img in imgs) {
                              final b = await img.readAsBytes();
                              setDialogState(() => pendingImages.add(_PendingVehicleImage(img, b)));
                            }
                          },
                          icon: Icon(pendingImages.isEmpty ? Icons.add_a_photo : Icons.add_photo_alternate, size: 18),
                          label: Text(pendingImages.isEmpty ? 'Upload New Photos' : 'Add More Photos'),
                          style: CustomerGarageFormFields.dialogButtonStyle(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomerGarageFormFields.formHeader('BASIC INFORMATION'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: CustomerGarageFormFields.textField(makeController, 'Make (e.g. Toyota)', Icons.branding_watermark)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(modelController, 'Model (e.g. Hilux)', Icons.car_rental)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: CustomerGarageFormFields.textField(yearController, 'Year', Icons.calendar_today)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(plateController, 'Plate Number', Icons.credit_card)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CustomerGarageFormFields.formHeader('MECHANICAL HEALTH & STATUS'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: CustomerGarageFormFields.textField(mileageController, 'Current Meter Reading (KM)', Icons.speed)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(nextServiceController, 'Next Service Due (KM)', Icons.event_repeat)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.dropdown(
                    'Tire Condition',
                    tireHealth,
                    const ['Brand New', 'Good', 'Fair', 'Needs Replacement'],
                    (v) => setDialogState(() => tireHealth = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: CustomerGarageFormFields.textField(oilLifeController, 'Oil Life (e.g. 80%)', Icons.oil_barrel)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(brakeFluidController, 'Brake Fluid Status', Icons.water_drop)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.textField(activeFaultsController, 'Active Faults (Log any known issues)', Icons.error_outline, maxLines: 2),
                  const SizedBox(height: 32),
                  CustomerGarageFormFields.formHeader('DOCUMENTATION & HISTORY'),
                  const SizedBox(height: 12),
                  CustomerGarageFormFields.textField(vinController, 'VIN (17-character Identifier)', Icons.fingerprint),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.dropdown(
                    'Service History',
                    serviceHistory,
                    const ['Full Service History (FSH)', 'Partial', 'None'],
                    (v) => setDialogState(() => serviceHistory = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomerGarageFormFields.datePickerTile(context, 'License Renewal', licenseRenewal, (d) => setDialogState(() => licenseRenewal = d)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Spare Key', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          value: spareKey,
                          onChanged: (v) => setDialogState(() => spareKey = v),
                          activeThumbColor: BoostDriveTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.dropdown(
                    'Accident History',
                    accidentHistory,
                    const ['No', 'Minor', 'Major (Repaired)', 'Write-off'],
                    (v) => setDialogState(() => accidentHistory = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomerGarageFormFields.datePickerTile(context, 'Insurance Expiry', insuranceExpiry, (d) => setDialogState(() => insuranceExpiry = d)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomerGarageFormFields.datePickerTile(context, 'Warranty Expiry', warrantyExpiry, (d) => setDialogState(() => warrantyExpiry = d)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  CustomerGarageFormFields.formHeader('USAGE & FEATURES (LISTING ENHANCEMENTS)'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: CustomerGarageFormFields.textField(efficiencyController, 'Fuel Efficiency (L/100km)', Icons.eco)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(capacityController, 'Engine Capacity', Icons.settings_input_component)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomerGarageFormFields.dropdown('Transmission', transmission, const ['Manual', 'Automatic'], (v) => setDialogState(() => transmission = v!)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomerGarageFormFields.dropdown(
                          'Fuel Type',
                          fuelType,
                          const ['Diesel', 'Petrol', 'Hybrid', 'Electric'],
                          (v) => setDialogState(() => fuelType = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.dropdown('Drive Type', driveType, const ['4x2', '4x2 (Raised Body)', '4x4'], (v) => setDialogState(() => driveType = v!)),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.textField(modificationController, 'Vehicle Modifications', Icons.build_circle, maxLines: 2),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.textField(exteriorController, 'Exterior Condition (Dents/Scratches)', Icons.edit_note, maxLines: 2),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomerGarageFormFields.dropdown(
                          'Interior Material',
                          interiorMaterial,
                          const ['Cloth', 'Leatherette', 'Leather', 'Canvas'],
                          (v) => setDialogState(() => interiorMaterial = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(towingController, 'Tow Bar / Towing Capacity', Icons.anchor)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.textField(safetyController, 'Safety Rating / Driver Assist Tech', Icons.security),
                  const SizedBox(height: 16),
                  CustomerGarageFormFields.textField(descriptionController, 'General Owner Description', Icons.description, maxLines: 3),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: BoostDriveTheme.textDim)),
            ),
            SizedBox(
              height: 48,
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoostDriveTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                        try {
                          final make = makeController.text.trim();
                          final model = modelController.text.trim();
                          final plate = plateController.text.trim();
                          final year = int.tryParse(yearController.text.trim());
                          final currentYear = DateTime.now().year + 1;
                          if (make.isEmpty || model.isEmpty || plate.isEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Make, model, and plate number are required.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                          if (year == null || year < 1900 || year > currentYear) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid vehicle year.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          List<String> imageUrls = vehicle?.imageUrls != null ? List<String>.from(vehicle!.imageUrls) : [];

                          if (pendingImages.isNotEmpty) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Row(
                                    children: [
                                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 12),
                                      Text('Uploading new photos...'),
                                    ],
                                  ),
                                ),
                              );
                            }
                            for (final p in pendingImages) {
                              final url = await ref.read(vehicleServiceProvider).uploadVehicleImage(uid, p.bytes, p.file.name);
                              if (url != null) imageUrls.add(url);
                            }
                          }

                          final updatedVehicle = Vehicle(
                            id: vehicle?.id ?? '',
                            ownerId: uid,
                            make: make,
                            model: model,
                            year: year,
                            plateNumber: plate,
                            mileage: int.tryParse(mileageController.text) ?? 0,
                            tireHealth: tireHealth,
                            serviceHistoryType: serviceHistory,
                            transmission: transmission,
                            fuelType: fuelType,
                            driveType: driveType,
                            engineCapacity: capacityController.text,
                            nextLicenseRenewal: licenseRenewal,
                            accidentHistory: accidentHistory,
                            modifications: modificationController.text,
                            spareKey: spareKey,
                            interiorMaterial: interiorMaterial,
                            safetyTech: safetyController.text,
                            towingCapacity: towingController.text,
                            description: descriptionController.text,
                            imageUrls: imageUrls,
                            createdAt: vehicle?.createdAt ?? DateTime.now(),
                            nextServiceDueMileage: int.tryParse(nextServiceController.text),
                            oilLife: oilLifeController.text,
                            brakeFluidStatus: brakeFluidController.text,
                            activeFaults: activeFaultsController.text,
                            vin: vinController.text,
                            insuranceExpiry: insuranceExpiry,
                            warrantyExpiry: warrantyExpiry,
                            fuelEfficiency: efficiencyController.text,
                            exteriorCondition: exteriorController.text,
                          );

                          if (vehicle == null) {
                            await ref.read(vehicleServiceProvider).addVehicle(updatedVehicle);
                          } else {
                            await ref.read(vehicleServiceProvider).updateVehicle(updatedVehicle);
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(vehicle == null ? 'Vehicle added successfully!' : 'Vehicle updated successfully!')),
                            );
                            Navigator.pop(context);
                            ref.read(dashboardRefreshProvider.notifier).update((s) => s + 1);
                            ref.invalidate(userVehiclesProvider(uid));
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving vehicle: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                child: Text(isSaving ? 'Saving...' : 'Save Vehicle', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    ),
  ).whenComplete(() {
    makeController.dispose();
    modelController.dispose();
    yearController.dispose();
    plateController.dispose();
    mileageController.dispose();
    capacityController.dispose();
    descriptionController.dispose();
    modificationController.dispose();
    safetyController.dispose();
    towingController.dispose();
    nextServiceController.dispose();
    oilLifeController.dispose();
    brakeFluidController.dispose();
    activeFaultsController.dispose();
    vinController.dispose();
    efficiencyController.dispose();
    exteriorController.dispose();
  });
}
