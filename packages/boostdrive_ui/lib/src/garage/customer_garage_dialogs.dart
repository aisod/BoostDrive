import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' as image_picker;
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';

import 'package:google_fonts/google_fonts.dart';

import '../dashboard_palette.dart';
import '../theme.dart';
import 'customer_garage_form_fields.dart';
import 'customer_garage_ui.dart';

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
              CustomerGarageFormFields.infoRow(context, 'Current Meter Reading', '${vehicle.mileage} KM'),
              CustomerGarageFormFields.infoRow(context, 
                'Next Service Due',
                vehicle.nextServiceDueMileage != null ? '${vehicle.nextServiceDueMileage} KM' : 'Not Set',
              ),
              CustomerGarageFormFields.infoRow(context, 'Tire Condition', vehicle.tireHealth),
              CustomerGarageFormFields.infoRow(context, 'Oil Life', vehicle.oilLife ?? 'Not Logged'),
              CustomerGarageFormFields.infoRow(context, 'Brake Fluid Status', vehicle.brakeFluidStatus ?? 'Healthy'),
              CustomerGarageFormFields.infoRow(context, 'Active Faults', vehicle.activeFaults ?? 'None Identified'),
            ]),
            _detailCategory(Icons.description, 'DOCUMENTATION & HISTORY', [
              CustomerGarageFormFields.infoRow(context, 'VIN', vehicle.vin ?? 'Not Provided'),
              CustomerGarageFormFields.infoRow(context, 'Service History', vehicle.serviceHistoryType),
              CustomerGarageFormFields.infoRow(context, 
                'License Renewal',
                vehicle.nextLicenseRenewal != null
                    ? '${vehicle.nextLicenseRenewal!.day}/${vehicle.nextLicenseRenewal!.month}/${vehicle.nextLicenseRenewal!.year}'
                    : 'Not Set',
              ),
              CustomerGarageFormFields.infoRow(context, 
                'Insurance Expiry',
                vehicle.insuranceExpiry != null
                    ? '${vehicle.insuranceExpiry!.day}/${vehicle.insuranceExpiry!.month}/${vehicle.insuranceExpiry!.year}'
                    : 'Not Logged',
              ),
              CustomerGarageFormFields.infoRow(context, 
                'Warranty Expiry',
                vehicle.warrantyExpiry != null
                    ? '${vehicle.warrantyExpiry!.day}/${vehicle.warrantyExpiry!.month}/${vehicle.warrantyExpiry!.year}'
                    : 'N/A',
              ),
              CustomerGarageFormFields.infoRow(context, 'Spare Key', vehicle.spareKey ? 'Yes' : 'No'),
            ]),
            _detailCategory(Icons.style, 'USAGE & FEATURES', [
              CustomerGarageFormFields.infoRow(context, 'Fuel Efficiency', vehicle.fuelEfficiency ?? 'Not Logged'),
              CustomerGarageFormFields.infoRow(context, 'Make & Model', '${vehicle.year} ${vehicle.make} ${vehicle.model}'),
              CustomerGarageFormFields.infoRow(context, 'Transmission', vehicle.transmission),
              CustomerGarageFormFields.infoRow(context, 'Fuel Type', vehicle.fuelType),
              CustomerGarageFormFields.infoRow(context, 'Drive Type', vehicle.driveType),
              CustomerGarageFormFields.infoRow(context, 'Engine Capacity', vehicle.engineCapacity ?? 'Not Specified'),
              CustomerGarageFormFields.infoRow(context, 'Exterior Condition', vehicle.exteriorCondition ?? 'Good'),
              CustomerGarageFormFields.infoRow(context, 'Interior Material', vehicle.interiorMaterial),
              CustomerGarageFormFields.infoRow(context, 'Towing Capacity', vehicle.towingCapacity ?? 'None'),
              CustomerGarageFormFields.infoRow(context, 'Safety Rating / Tech', vehicle.safetyTech ?? 'Standard'),
            ]),
            if (vehicle.description != null && vehicle.description!.isNotEmpty) ...[
              const SizedBox(height: 32),
              CustomerGarageFormFields.formHeader(context, 'OWNER DESCRIPTION'),
              const SizedBox(height: 12),
              Text(vehicle.description!, style: const TextStyle(color: Colors.white70, height: 1.5)),
            ],
            if (vehicle.modifications != null && vehicle.modifications!.isNotEmpty) ...[
              const SizedBox(height: 32),
              CustomerGarageFormFields.formHeader(context, 'MODIFICATIONS & EXTRAS'),
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
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final dateLabel = '${months[record.completedAt.month - 1]} ${record.completedAt.day}, ${record.completedAt.year}';
  final recordId = record.id.length > 8 ? record.id.substring(0, 8).toUpperCase() : record.id.toUpperCase();

  CustomerGarageUi.showSheet<void>(
    context: context,
    title: 'Service Record',
    trailing: [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          'ID: #$recordId',
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFF6600),
            letterSpacing: 0.5,
          ),
        ),
      ),
    ],
    bodyBuilder: (sheetContext, scrollController) {
      final palette = DashboardPalette.of(sheetContext);
      return ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(
          CustomerGarageUi.marginMobile,
          0,
          CustomerGarageUi.marginMobile,
          32,
        ),
        children: [
          CustomerGarageUi.serviceHeroCard(
            palette: palette,
            serviceName: record.serviceName,
            imageUrls: record.receiptUrls.isNotEmpty ? record.receiptUrls : null,
          ),
          const SizedBox(height: 20),
          CustomerGarageUi.detailMetricRow(
            palette: palette,
            icon: Icons.payments_outlined,
            iconBg: palette.primaryContainer.withValues(alpha: 0.12),
            iconColor: palette.primaryContainer,
            label: 'Total Cost',
            value: 'N\$ ${record.price.toStringAsFixed(2)}',
          ),
          CustomerGarageUi.detailMetricRow(
            palette: palette,
            icon: Icons.calendar_today_outlined,
            iconBg: palette.isDark
                ? const Color(0xFF1E3A5F)
                : const Color(0xFFD1E4FF),
            iconColor: palette.isDark ? const Color(0xFF9CCAFF) : const Color(0xFF0061A4),
            label: 'Service Date',
            value: dateLabel,
          ),
          if (record.mileageAtService != null)
            CustomerGarageUi.detailMetricRow(
              palette: palette,
              icon: Icons.speed_outlined,
              iconBg: palette.surfaceContainer,
              iconColor: palette.onSurfaceVariant,
              label: 'Mileage',
              value: '${record.mileageAtService} KM',
            ),
          if (record.receiptUrls.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECEIPTS / PROOFS',
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: palette.title,
                  ),
                ),
                Text(
                  '${record.receiptUrls.length} ATTACHMENTS',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.primaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: record.receiptUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () => showCustomerViewReceiptDialog(context, record.receiptUrls[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
                    child: Image.network(
                      record.receiptUrls[index],
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(sheetContext),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
                ),
              ),
              child: Text(
                'CLOSE',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      );
    },
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

  Future<void> submitRecord(BuildContext sheetContext, void Function(void Function()) setDialogState) async {
    try {
      setDialogState(() => isSaving = true);
      List<String> imageUrls = record?.receiptUrls != null ? List<String>.from(record!.receiptUrls) : [];

      if (pendingReceipts.isNotEmpty) {
        if (sheetContext.mounted) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
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

      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).clearSnackBars();
        ScaffoldMessenger.of(sheetContext).showSnackBar(
          SnackBar(content: Text(record == null ? 'Service record saved to your Digital Logbook!' : 'Service record updated!')),
        );
        Navigator.pop(sheetContext);
        ref.read(dashboardRefreshProvider.notifier).update((s) => s + 1);
        ref.invalidate(vehicleHistoryProvider(vehicleId));
        ref.invalidate(userServiceHistoryProvider(uid));
      }
    } catch (e) {
      setDialogState(() => isSaving = false);
      if (sheetContext.mounted) {
        ScaffoldMessenger.of(sheetContext).clearSnackBars();
        ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
      }
    }
  }

  CustomerGarageUi.showSheet<void>(
    context: context,
    title: record == null ? 'Log Service' : 'Edit Service',
    bodyBuilder: (sheetContext, scrollController) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final palette = DashboardPalette.of(context);
          final receiptCount = (record?.receiptUrls.length ?? 0) + pendingReceipts.length;
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              CustomerGarageUi.marginMobile,
              0,
              CustomerGarageUi.marginMobile,
              32,
            ),
            children: [
              Center(child: CustomerGarageUi.logServiceHeaderBadge(palette)),
              const SizedBox(height: 24),
              CustomerGarageFormFields.textField(
                context,
                serviceController,
                'Service Name',
                Icons.handyman,
                hint: 'e.g. Full Synthetic Oil Change',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomerGarageFormFields.textField(
                      context,
                      priceController,
                      'Cost (N\$)',
                      Icons.payments,
                      hint: '0.00',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomerGarageFormFields.textField(
                      context,
                      mileageController,
                      'Mileage (KM)',
                      Icons.speed,
                      hint: '0',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomerGarageFormFields.formHeader(context, 'SERVICE RECEIPTS / INVOICES'),
                  if (receiptCount > 0)
                    Text(
                      '$receiptCount FILES',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: palette.muted,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CustomerGarageUi.uploadReceiptTile(
                      palette: palette,
                      onTap: () async {
                        final imgs = await imagePicker.pickMultiImage();
                        if (imgs.isEmpty) return;
                        for (final img in imgs) {
                          final b = await img.readAsBytes();
                          setDialogState(() => pendingReceipts.add(_PendingReceipt(img, b)));
                        }
                      },
                    ),
                    if (record != null)
                      ...record!.receiptUrls.map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(CustomerGarageUi.radiusControl),
                            child: Image.network(
                              url,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 120,
                                height: 120,
                                color: palette.primaryContainer.withValues(alpha: 0.1),
                                child: Icon(Icons.broken_image, color: palette.primaryContainer),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...pendingReceipts.asMap().entries.map(
                      (entry) => CustomerGarageUi.pendingThumb(
                        bytes: entry.value.bytes,
                        onRemove: () => setDialogState(() => pendingReceipts.removeAt(entry.key)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              CustomerGarageUi.sheetFooter(
                palette: palette,
                onCancel: () => Navigator.pop(sheetContext),
                onPrimary: isSaving ? null : () => submitRecord(sheetContext, setDialogState),
                primaryLabel: isSaving ? 'SAVING...' : 'SUBMIT RECORD',
                primaryLoading: isSaving,
                primaryIcon: Icons.send_rounded,
              ),
            ],
          );
        },
      );
    },
  ).whenComplete(() {
    serviceController.dispose();
    priceController.dispose();
    mileageController.dispose();
  });
}
