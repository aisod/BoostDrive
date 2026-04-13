import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

import '../theme.dart';
import 'customer_garage_form_fields.dart';

export 'customer_garage_add_vehicle_dialog.dart' show showCustomerAddVehicleDialog;

void showCustomerVehicleDetailsModal(BuildContext context, WidgetRef ref, Vehicle vehicle) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: BoostDriveTheme.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${vehicle.year} ${vehicle.make} ${vehicle.model}',
                    style: const TextStyle(fontFamily: 'Manrope', fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 8),
            Text(vehicle.plateNumber, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 16)),
            const SizedBox(height: 24),
            if (vehicle.imageUrls.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: vehicle.imageUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => showCustomerViewReceiptDialog(context, vehicle.imageUrls[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(vehicle.imageUrls[index], width: 300, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 32),
            _detailCategory(Icons.speed, 'MECHANICAL HEALTH & STATUS', [
              CustomerGarageFormFields.infoRow('Current Meter Reading', '${vehicle.mileage} KM'),
              CustomerGarageFormFields.infoRow(
                'Next Service Due',
                vehicle.nextServiceDueMileage != null ? '${vehicle.nextServiceDueMileage} KM' : 'Not Set',
              ),
              CustomerGarageFormFields.infoRow('Tire Condition', vehicle.tireHealth),
              CustomerGarageFormFields.infoRow('Oil Life', vehicle.oilLife ?? 'Not Logged'),
              CustomerGarageFormFields.infoRow('Brake Fluid Status', vehicle.brakeFluidStatus ?? 'Healthy'),
              CustomerGarageFormFields.infoRow('Active Faults', vehicle.activeFaults ?? 'None Identified'),
            ]),
            _detailCategory(Icons.description, 'DOCUMENTATION & HISTORY', [
              CustomerGarageFormFields.infoRow('VIN', vehicle.vin ?? 'Not Provided'),
              CustomerGarageFormFields.infoRow('Service History', vehicle.serviceHistoryType),
              CustomerGarageFormFields.infoRow(
                'License Renewal',
                vehicle.nextLicenseRenewal != null
                    ? '${vehicle.nextLicenseRenewal!.day}/${vehicle.nextLicenseRenewal!.month}/${vehicle.nextLicenseRenewal!.year}'
                    : 'Not Set',
              ),
              CustomerGarageFormFields.infoRow(
                'Insurance Expiry',
                vehicle.insuranceExpiry != null
                    ? '${vehicle.insuranceExpiry!.day}/${vehicle.insuranceExpiry!.month}/${vehicle.insuranceExpiry!.year}'
                    : 'Not Logged',
              ),
              CustomerGarageFormFields.infoRow(
                'Warranty Expiry',
                vehicle.warrantyExpiry != null
                    ? '${vehicle.warrantyExpiry!.day}/${vehicle.warrantyExpiry!.month}/${vehicle.warrantyExpiry!.year}'
                    : 'N/A',
              ),
              CustomerGarageFormFields.infoRow('Spare Key', vehicle.spareKey ? 'Yes' : 'No'),
            ]),
            _detailCategory(Icons.style, 'USAGE & FEATURES', [
              CustomerGarageFormFields.infoRow('Fuel Efficiency', vehicle.fuelEfficiency ?? 'Not Logged'),
              CustomerGarageFormFields.infoRow('Make & Model', '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
              CustomerGarageFormFields.infoRow('Transmission', vehicle.transmission),
              CustomerGarageFormFields.infoRow('Fuel Type', vehicle.fuelType),
              CustomerGarageFormFields.infoRow('Drive Type', vehicle.driveType),
              CustomerGarageFormFields.infoRow('Engine Capacity', vehicle.engineCapacity ?? 'Not Specified'),
              CustomerGarageFormFields.infoRow('Exterior Condition', vehicle.exteriorCondition ?? 'Good'),
              CustomerGarageFormFields.infoRow('Interior Material', vehicle.interiorMaterial),
              CustomerGarageFormFields.infoRow('Towing Capacity', vehicle.towingCapacity ?? 'None'),
              CustomerGarageFormFields.infoRow('Safety Rating / Tech', vehicle.safetyTech ?? 'Standard'),
            ]),
            if (vehicle.description != null && vehicle.description!.isNotEmpty) ...[
              const SizedBox(height: 32),
              CustomerGarageFormFields.formHeader('OWNER DESCRIPTION'),
              const SizedBox(height: 12),
              Text(vehicle.description!, style: const TextStyle(color: Colors.white70, height: 1.5)),
            ],
            if (vehicle.modifications != null && vehicle.modifications!.isNotEmpty) ...[
              const SizedBox(height: 32),
              CustomerGarageFormFields.formHeader('MODIFICATIONS & EXTRAS'),
              const SizedBox(height: 12),
              Text(vehicle.modifications!, style: const TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showCustomerLogServiceDialog(context, ref, vehicle.ownerId, vehicle.id);
                },
                icon: const Icon(Icons.history_edu),
                label: const Text('Update Digital Logbook'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoostDriveTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}

Widget _detailCategory(IconData icon, String title, List<Widget> children) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      Row(
        children: [
          Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: BoostDriveTheme.primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      ...children,
    ],
  );
}

void showCustomerViewReceiptDialog(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(url, fit: BoxFit.contain),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void showCustomerViewReceiptsDialog(BuildContext context, List<String> urls) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              Container(
                constraints: const BoxConstraints(maxHeight: 600, maxWidth: 800),
                child: ListView.separated(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: urls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(urls[index], fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

void confirmDeleteCustomerVehicle(BuildContext context, WidgetRef ref, Vehicle vehicle) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: BoostDriveTheme.surfaceDark,
      title: const Text('Delete Vehicle', style: TextStyle(color: Colors.white)),
      content: Text(
        'Are you sure you want to delete ${vehicle.year} ${vehicle.make} ${vehicle.model}? This action cannot be undone.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ref.read(vehicleServiceProvider).deleteVehicle(vehicle.id);
            if (context.mounted) {
              Navigator.pop(context);
              ref.read(dashboardRefreshProvider.notifier).update((s) => s + 1);
              ref.invalidate(userVehiclesProvider(vehicle.ownerId));
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void confirmDeleteCustomerServiceRecord(BuildContext context, WidgetRef ref, String uid, ServiceRecord record) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: BoostDriveTheme.surfaceDark,
      title: const Text('Delete Service Record', style: TextStyle(color: Colors.white)),
      content: Text(
        'Are you sure you want to delete the record for "${record.serviceName}"? This action cannot be undone.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            try {
              await ref.read(serviceRecordServiceProvider).deleteServiceRecord(record.id);
              if (context.mounted) {
                Navigator.pop(context);
                ref.read(dashboardRefreshProvider.notifier).update((s) => s + 1);
                ref.invalidate(vehicleHistoryProvider(record.vehicleId));
                ref.invalidate(userServiceHistoryProvider(uid));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service record deleted successfully')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
              }
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void showCustomerServiceRecordDetailsDialog(BuildContext context, ServiceRecord record) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: BoostDriveTheme.surfaceDark,
      title: Text(record.serviceName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomerGarageFormFields.infoRow('Cost', 'N\$ ${record.price.toStringAsFixed(2)}'),
              CustomerGarageFormFields.infoRow('Date', '${record.completedAt.day}/${record.completedAt.month}/${record.completedAt.year}'),
              if (record.mileageAtService != null) CustomerGarageFormFields.infoRow('Mileage', '${record.mileageAtService} KM'),
              const SizedBox(height: 24),
              if (record.receiptUrls.isNotEmpty) ...[
                const Text('RECEIPTS / PROOFS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: record.receiptUrls.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => showCustomerViewReceiptDialog(context, record.receiptUrls[index]),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(record.receiptUrls[index], height: 200, width: 200, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    ),
  );
}

class _PendingReceipt {
  _PendingReceipt(this.file, this.bytes);
  final image_picker.XFile file;
  final Uint8List bytes;
}

void showCustomerLogServiceDialog(
  BuildContext context,
  WidgetRef ref,
  String uid,
  String vehicleId, {
  ServiceRecord? record,
}) {
  final serviceController = TextEditingController(text: record?.serviceName);
  final priceController = TextEditingController(text: record?.price.toString());
  final mileageController = TextEditingController(text: record?.mileageAtService?.toString());
  final imagePicker = image_picker.ImagePicker();
  final pendingReceipts = <_PendingReceipt>[];
  bool isSaving = false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          title: Row(
            children: [
              Flexible(
                child: Text(
                  record == null ? 'Log Service Record' : 'Edit Service Record',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (isSaving) ...[
                const SizedBox(width: 16),
                const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: BoostDriveTheme.primaryColor)),
              ],
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerGarageFormFields.textField(serviceController, 'Service Name (e.g. Oil Change)', Icons.handyman),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: CustomerGarageFormFields.textField(priceController, 'Cost (N\$)', Icons.payments)),
                      const SizedBox(width: 16),
                      Expanded(child: CustomerGarageFormFields.textField(mileageController, 'Mileage (KM)', Icons.speed)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  CustomerGarageFormFields.formHeader('SERVICE RECEIPTS / INVOICES (MULTIPLES)'),
                  const SizedBox(height: 12),
                  if (pendingReceipts.isNotEmpty || (record?.receiptUrls.isNotEmpty ?? false))
                    Container(
                      height: 120,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          if (record != null)
                            ...record!.receiptUrls.map(
                              (url) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 120,
                                      height: 120,
                                      color: const Color(0x22FF6600),
                                      child: const Icon(Icons.broken_image, color: Color(0x22FF6600)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ...pendingReceipts.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 120,
                                height: 120,
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(entry.value.bytes, width: 120, height: 120, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => setDialogState(() => pendingReceipts.removeAt(entry.key)),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final imgs = await imagePicker.pickMultiImage();
                        if (imgs.isEmpty) return;
                        for (final img in imgs) {
                          final b = await img.readAsBytes();
                          setDialogState(() => pendingReceipts.add(_PendingReceipt(img, b)));
                        }
                      },
                      icon: Icon(pendingReceipts.isEmpty ? Icons.receipt_long : Icons.add_photo_alternate, size: 18),
                      label: Text(pendingReceipts.isEmpty ? 'Upload New Receipts' : 'Add More Receipts'),
                      style: CustomerGarageFormFields.dialogButtonStyle(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: BoostDriveTheme.textDim)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: BoostDriveTheme.primaryColor),
              onPressed: isSaving
                  ? null
                  : () async {
                      try {
                        setDialogState(() => isSaving = true);
                        List<String> imageUrls = record?.receiptUrls != null ? List<String>.from(record!.receiptUrls) : [];

                        if (pendingReceipts.isNotEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Uploading new receipts...'), duration: Duration(seconds: 2)),
                            );
                          }
                          for (final p in pendingReceipts) {
                            final url = await ref.read(serviceRecordServiceProvider).uploadServiceReceipt(vehicleId, p.bytes, p.file.name);
                            if (url != null) imageUrls.add(url);
                          }
                        }

                        final updatedRecord = ServiceRecord(
                          id: record?.id ?? '',
                          vehicleId: vehicleId,
                          providerId: uid,
                          serviceName: serviceController.text,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          completedAt: record?.completedAt ?? DateTime.now(),
                          receiptUrls: imageUrls,
                          mileageAtService: int.tryParse(mileageController.text),
                        );

                        if (record == null) {
                          await ref.read(serviceRecordServiceProvider).addServiceRecord(updatedRecord);
                        } else {
                          await ref.read(serviceRecordServiceProvider).updateServiceRecord(updatedRecord);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(record == null ? 'Service record saved to your Digital Logbook!' : 'Service record updated!')),
                          );
                          Navigator.pop(context);
                          ref.read(dashboardRefreshProvider.notifier).update((s) => s + 1);
                          ref.invalidate(vehicleHistoryProvider(vehicleId));
                          ref.invalidate(userServiceHistoryProvider(uid));
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
                        }
                      }
                    },
              child: Text(isSaving ? 'Saving...' : 'Save to Logbook'),
            ),
          ],
        );
      },
    ),
  ).whenComplete(() {
    serviceController.dispose();
    priceController.dispose();
    mileageController.dispose();
  });
}
