import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// Provider stock, kits, and equipment readiness (reads `provider_inventory`, `service_kits`, `provider_equipment`).
class ProviderInventoryPage extends ConsumerStatefulWidget {
  const ProviderInventoryPage({super.key});

  @override
  ConsumerState<ProviderInventoryPage> createState() => _ProviderInventoryPageState();
}

class _ProviderInventoryPageState extends ConsumerState<ProviderInventoryPage> {
  final _search = TextEditingController();
  final _barcodeField = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    // Dispose page-level text controllers.
    _search.dispose();
    _barcodeField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    // Provider ID is required to scope inventory and operations data.
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: Text('Please log in', style: DashboardTypography.bodyMd(palette))),
      );
    }

    final profile = ref.watch(userProfileProvider(uid)).valueOrNull;
    final invAsync = ref.watch(_providerInventoryFamily(uid));
    final equipAsync = ref.watch(_providerEquipmentFamily(uid));
    final kitsAsync = ref.watch(_serviceKitsFamily(uid));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileProviderUi.glassAppBar(
        context: context,
        palette: palette,
        title: 'INVENTORY',
        avatar: MobileProviderUi.profileAvatar(
          palette: palette,
          imageUrl: profile?.profileImg,
        ),
      ),
      body: RefreshIndicator(
        color: palette.primaryContainer,
        onRefresh: () async {
          ref.invalidate(_providerInventoryFamily(uid));
          ref.invalidate(_providerEquipmentFamily(uid));
          ref.invalidate(_serviceKitsFamily(uid));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            MobileProviderUi.marginMobile,
            12,
            MobileProviderUi.marginMobile,
            120,
          ),
          children: [
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: DashboardTypography.bodyMd(palette).copyWith(color: palette.title),
              decoration: MobileProviderUi.searchDecoration(
                palette,
                hint: 'Search SKU, part name, or category…',
              ),
            ),
            const SizedBox(height: 16),
            invAsync.when(
              data: (rows) {
                final low = rows.where((r) {
                  final q = (r['stock_quantity'] as num?)?.toInt() ?? 0;
                  final th = (r['low_stock_threshold'] as num?)?.toInt() ?? 0;
                  return q <= th;
                }).length;
                final mobileReady = rows.where((r) => r['available_for_mobile'] == true).length;
                final pct = rows.isEmpty ? 100 : ((mobileReady / rows.length) * 100).round();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                      children: [
                        MobileProviderUi.bentoStatCard(
                          palette: palette,
                          label: 'Total Items',
                          value: '${rows.length}',
                          icon: Icons.inventory_2,
                        ),
                        MobileProviderUi.bentoStatCard(
                          palette: palette,
                          label: 'Low Stock',
                          value: '$low',
                          icon: Icons.warning,
                          iconColor: palette.error,
                          valueColor: palette.error,
                        ),
                        MobileProviderUi.bentoStatCard(
                          palette: palette,
                          label: 'Mobile Ready',
                          value: '$pct%',
                          icon: Icons.local_shipping,
                          iconColor: palette.tertiary,
                        ),
                        MobileProviderUi.bentoStatCard(
                          palette: palette,
                          label: 'In Catalog',
                          value: '${rows.length}',
                          icon: Icons.payments,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    MobileProviderUi.sectionTitle(palette, 'Quick-add (barcode)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barcodeField,
                            style: TextStyle(color: palette.title),
                            decoration: MobileProviderUi.fieldDecoration(
                              palette,
                              hint: 'Scan or type barcode',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () async {
                            final code = _barcodeField.text.trim();
                            if (code.isEmpty) return;
                            try {
                              await ref.read(providerOpsServiceProvider).insertInventoryItem(
                                    providerId: uid,
                                    name: 'Item $code',
                                    barcode: code,
                                    stockQuantity: 1,
                                  );
                              _barcodeField.clear();
                              ref.invalidate(_providerInventoryFamily(uid));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock line added')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            }
                          },
                          child: const Text('ADD'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera-based scanning can plug in via mobile_scanner later; barcode is stored on the row.',
                      style: DashboardTypography.bodySm(palette),
                    ),
                    const SizedBox(height: 20),
                    MobileProviderUi.listSection(
                      palette: palette,
                      title: 'Stock Details',
                      child: Column(
                        children: _filteredInventory(rows, _query)
                            .map((r) => _inventoryTile(context, palette, uid, r))
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => _errorBox(
                'Could not load inventory. Apply the Supabase migration and ensure RLS allows your user.\n$e',
              ),
            ),
            const SizedBox(height: 28),
            MobileProviderUi.sectionTitle(palette, 'Service kits'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _addServiceKit(context, uid),
                icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                label: const Text('Add kit', style: TextStyle(color: Colors.white70)),
              ),
            ),
            kitsAsync.when(
              data: (kits) {
                if (kits.isEmpty) {
                  return Text(
                    'No kits yet — create bundles in Supabase or a future editor.',
                    style: DashboardTypography.bodySm(palette),
                  );
                }
                return Column(
                  children: kits
                      .map(
                        (k) => Card(
                          color: MobileProviderUi.cardSurface(palette),
                          child: ListTile(
                            title: Text(k['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              k['vehicle_notes']?.toString() ?? k['description']?.toString() ?? '',
                              style: DashboardTypography.bodySm(palette),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit kit',
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                  onPressed: () => _editServiceKit(context, uid, k),
                                ),
                                IconButton(
                                  tooltip: 'Delete kit',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _deleteServiceKit(context, uid, k),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const SizedBox(),
              error: (e, _) => Text('Kits: $e', style: TextStyle(color: Colors.red.shade200, fontSize: 12)),
            ),
            const SizedBox(height: 28),
            MobileProviderUi.sectionTitle(palette, 'Equipment status'),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _addEquipment(context, uid),
                icon: const Icon(Icons.add, size: 16, color: Colors.white70),
                label: const Text('Add equipment', style: TextStyle(color: Colors.white70)),
              ),
            ),
            equipAsync.when(
              data: (eq) {
                if (eq.isEmpty) {
                  return Text('No equipment rows — add hitches, jacks, scanners as lines in provider_equipment.',
                      style: DashboardTypography.bodySm(palette));
                }
                return Column(
                  children: eq
                      .map(
                        (r) => Card(
                          color: MobileProviderUi.cardSurface(palette),
                          child: ListTile(
                            title: Text(r['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Status: ${r['status']}', style: DashboardTypography.bodySm(palette)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit equipment',
                                  icon: const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                                  onPressed: () => _editEquipment(context, uid, r),
                                ),
                                IconButton(
                                  tooltip: 'Delete equipment',
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _deleteEquipment(context, uid, r),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const SizedBox(),
              error: (e, _) => Text('Equipment: $e', style: TextStyle(color: Colors.red.shade200, fontSize: 12)),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('https://www.google.com/search?q=Namibia+auto+parts+wholesaler');
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new, color: Colors.white70),
              label: const Text('Restock (find suppliers)', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filteredInventory(List<Map<String, dynamic>> rows, String q) {
    // Filter rows by name, SKU, or barcode.
    if (q.isEmpty) return rows;
    return rows.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final sku = (r['sku'] ?? '').toString().toLowerCase();
      final bc = (r['barcode'] ?? '').toString().toLowerCase();
      return name.contains(q) || sku.contains(q) || bc.contains(q);
    }).toList();
  }

  Widget _inventoryTile(BuildContext context, DashboardPalette palette, String uid, Map<String, dynamic> r) {
    // Single inventory row with edit/delete/mobile-availability actions.
    final qty = (r['stock_quantity'] as num?)?.toInt() ?? 0;
    final th = (r['low_stock_threshold'] as num?)?.toInt() ?? 0;
    final low = qty <= th;
    final mobile = r['available_for_mobile'] == true;
    return MobileProviderUi.listTileCard(
      palette: palette,
      title: Text(r['name']?.toString() ?? ''),
      subtitle: Text('Qty $qty · threshold $th · ${r['item_category'] ?? 'part'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            low ? Icons.warning_amber : Icons.build_circle_outlined,
            color: low ? palette.error : palette.muted,
            size: 22,
          ),
          IconButton(
            tooltip: 'Edit item',
            icon: Icon(Icons.edit_outlined, size: 18, color: palette.muted),
            onPressed: () => _editInventoryItem(context, uid, r),
          ),
          IconButton(
            tooltip: 'Delete item',
            icon: Icon(Icons.delete_outline, size: 18, color: palette.error),
            onPressed: () => _deleteInventoryItem(context, uid, r),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mobile', style: DashboardTypography.labelMd(palette).copyWith(fontSize: 9)),
              Switch.adaptive(
                value: mobile,
                activeTrackColor: palette.primaryContainer,
                onChanged: (v) async {
                  try {
                    await ref.read(providerOpsServiceProvider).setInventoryMobileAvailability(
                          inventoryRowId: r['id'].toString(),
                          availableForMobile: v,
                        );
                    ref.invalidate(_providerInventoryFamily(uid));
                  } catch (_) {}
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editInventoryItem(BuildContext context, String uid, Map<String, dynamic> row) async {
    // Opens dialog to edit inventory row details.
    final name = TextEditingController(text: row['name']?.toString() ?? '');
    final qty = TextEditingController(text: '${(row['stock_quantity'] as num?)?.toInt() ?? 0}');
    final threshold = TextEditingController(text: '${(row['low_stock_threshold'] as num?)?.toInt() ?? 5}');
    final sku = TextEditingController(text: row['sku']?.toString() ?? '');
    final barcode = TextEditingController(text: row['barcode']?.toString() ?? '');
    final category = TextEditingController(text: row['item_category']?.toString() ?? 'part');
    final description = TextEditingController(text: row['description']?.toString() ?? '');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Edit inventory item', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField(name, 'Name'),
              _editField(qty, 'Quantity', keyboard: TextInputType.number),
              _editField(threshold, 'Low-stock threshold', keyboard: TextInputType.number),
              _editField(category, 'Category'),
              _editField(sku, 'SKU'),
              _editField(barcode, 'Barcode'),
              _editField(description, 'Description'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).updateInventoryItem(
              inventoryRowId: row['id'].toString(),
              name: name.text.trim().isEmpty ? 'Item' : name.text.trim(),
              description: description.text.trim(),
              sku: sku.text.trim(),
              barcode: barcode.text.trim(),
              stockQuantity: int.tryParse(qty.text.trim()) ?? 0,
              lowStockThreshold: int.tryParse(threshold.text.trim()) ?? 5,
              itemCategory: category.text.trim().isEmpty ? 'part' : category.text.trim(),
            );
        ref.invalidate(_providerInventoryFamily(uid));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item updated')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }

    name.dispose();
    qty.dispose();
    threshold.dispose();
    sku.dispose();
    barcode.dispose();
    category.dispose();
    description.dispose();
  }

  Future<void> _deleteInventoryItem(BuildContext context, String uid, Map<String, dynamic> row) async {
    // Confirm and delete selected inventory item.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Delete item?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${row['name'] ?? 'this item'}"?',
          style: TextStyle(color: DashboardPalette.of(context).muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).deleteInventoryItem(row['id'].toString());
        ref.invalidate(_providerInventoryFamily(uid));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Widget _editField(
    TextEditingController controller,
    String hint, {
    TextInputType keyboard = TextInputType.text,
  }) {
    // Reusable text field widget for add/edit dialogs.
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: DashboardPalette.of(context).muted),
          filled: true,
          fillColor: MobileProviderUi.fieldSurface(DashboardPalette.of(context)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
    // Styled error message container.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.35)),
    );
  }

  Future<void> _addServiceKit(BuildContext context, String uid) async {
    // Add a new service kit row.
    final name = TextEditingController();
    final desc = TextEditingController();
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Add service kit', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField(name, 'Kit name'),
              _editField(desc, 'Description'),
              _editField(notes, 'Vehicle notes'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).insertServiceKit(
              providerId: uid,
              name: name.text.trim().isEmpty ? 'Untitled kit' : name.text.trim(),
              description: desc.text.trim(),
              vehicleNotes: notes.text.trim(),
            );
        ref.invalidate(_serviceKitsFamily(uid));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    name.dispose();
    desc.dispose();
    notes.dispose();
  }

  Future<void> _editServiceKit(BuildContext context, String uid, Map<String, dynamic> kit) async {
    // Edit existing service kit row.
    final name = TextEditingController(text: kit['name']?.toString() ?? '');
    final desc = TextEditingController(text: kit['description']?.toString() ?? '');
    final notes = TextEditingController(text: kit['vehicle_notes']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Edit service kit', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField(name, 'Kit name'),
              _editField(desc, 'Description'),
              _editField(notes, 'Vehicle notes'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).updateServiceKit(
              kitRowId: kit['id'].toString(),
              name: name.text.trim().isEmpty ? 'Untitled kit' : name.text.trim(),
              description: desc.text.trim(),
              vehicleNotes: notes.text.trim(),
            );
        ref.invalidate(_serviceKitsFamily(uid));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    name.dispose();
    desc.dispose();
    notes.dispose();
  }

  Future<void> _deleteServiceKit(BuildContext context, String uid, Map<String, dynamic> kit) async {
    // Confirm and delete service kit row.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Delete kit?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${kit['name'] ?? 'this kit'}"?',
          style: TextStyle(color: DashboardPalette.of(context).muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).deleteServiceKit(kit['id'].toString());
        ref.invalidate(_serviceKitsFamily(uid));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _addEquipment(BuildContext context, String uid) async {
    // Add equipment row (name, status, notes).
    final name = TextEditingController();
    final notes = TextEditingController();
    final status = TextEditingController(text: 'available');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Add equipment', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField(name, 'Equipment name'),
              _editField(status, 'Status (available, maintenance, offline)'),
              _editField(notes, 'Notes'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).upsertEquipment(
              providerId: uid,
              name: name.text.trim().isEmpty ? 'Unnamed equipment' : name.text.trim(),
              status: status.text.trim().isEmpty ? 'available' : status.text.trim(),
              notes: notes.text.trim(),
            );
        ref.invalidate(_providerEquipmentFamily(uid));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    name.dispose();
    notes.dispose();
    status.dispose();
  }

  Future<void> _editEquipment(BuildContext context, String uid, Map<String, dynamic> row) async {
    // Edit equipment row details.
    final name = TextEditingController(text: row['name']?.toString() ?? '');
    final notes = TextEditingController(text: row['notes']?.toString() ?? '');
    final status = TextEditingController(text: row['status']?.toString() ?? 'available');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Edit equipment', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField(name, 'Equipment name'),
              _editField(status, 'Status'),
              _editField(notes, 'Notes'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('SAVE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).updateEquipment(
              equipmentRowId: row['id'].toString(),
              name: name.text.trim().isEmpty ? 'Unnamed equipment' : name.text.trim(),
              status: status.text.trim().isEmpty ? 'available' : status.text.trim(),
              notes: notes.text.trim(),
            );
        ref.invalidate(_providerEquipmentFamily(uid));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
    name.dispose();
    notes.dispose();
    status.dispose();
  }

  Future<void> _deleteEquipment(BuildContext context, String uid, Map<String, dynamic> row) async {
    // Confirm and delete equipment row.
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MobileProviderUi.cardSurface(DashboardPalette.of(context)),
        title: const Text('Delete equipment?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${row['name'] ?? 'this equipment'}"?',
          style: TextStyle(color: DashboardPalette.of(context).muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      try {
        await ref.read(providerOpsServiceProvider).deleteEquipment(row['id'].toString());
        ref.invalidate(_providerEquipmentFamily(uid));
      } catch (e) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

final _providerInventoryFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listProviderInventory(uid);
});

final _providerEquipmentFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listProviderEquipment(uid);
});

final _serviceKitsFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listServiceKits(uid);
});
