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
    _search.dispose();
    _barcodeField.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) {
      return const Center(child: Text('Please log in'));
    }

    final invAsync = ref.watch(_providerInventoryFamily(uid));
    final equipAsync = ref.watch(_providerEquipmentFamily(uid));
    final kitsAsync = ref.watch(_serviceKitsFamily(uid));

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: BoostDriveTheme.backgroundDark,
      child: SafeArea(
        child: RefreshIndicator(
          color: BoostDriveTheme.primaryColor,
          onRefresh: () async {
            ref.invalidate(_providerInventoryFamily(uid));
            ref.invalidate(_providerEquipmentFamily(uid));
            ref.invalidate(_serviceKitsFamily(uid));
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            const Text(
              'INVENTORY',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search parts, SKU, barcode…',
                hintStyle: TextStyle(color: BoostDriveTheme.textDim),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                    Row(
                      children: [
                        Expanded(child: _summaryCard('Total items', '${rows.length}', Icons.inventory_2_outlined)),
                        const SizedBox(width: 10),
                        Expanded(child: _summaryCard('Low stock', '$low', Icons.warning_amber_outlined)),
                        const SizedBox(width: 10),
                        Expanded(child: _summaryCard('Mobile ready', '$pct%', Icons.local_shipping_outlined)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Quick-add (barcode)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _barcodeField,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Scan or type barcode',
                              hintStyle: TextStyle(color: BoostDriveTheme.textDim),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.06),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
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
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11),
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('Parts & consumables'),
                    const SizedBox(height: 10),
                    ..._filteredInventory(rows, _query).map((r) => _inventoryTile(context, uid, r)),
                  ],
                );
              },
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => _errorBox(
                'Could not load inventory. Apply the Supabase migration and ensure RLS allows your user.\n$e',
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle('Service kits'),
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
                  return Text('No kits yet — create bundles in Supabase or a future editor.', style: TextStyle(color: BoostDriveTheme.textDim));
                }
                return Column(
                  children: kits
                      .map(
                        (k) => Card(
                          color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.55),
                          child: ListTile(
                            title: Text(k['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            subtitle: Text(
                              k['vehicle_notes']?.toString() ?? k['description']?.toString() ?? '',
                              style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
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
            _sectionTitle('Equipment status'),
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
                      style: TextStyle(color: BoostDriveTheme.textDim));
                }
                return Column(
                  children: eq
                      .map(
                        (r) => Card(
                          color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.55),
                          child: ListTile(
                            title: Text(r['name']?.toString() ?? '', style: const TextStyle(color: Colors.white)),
                            subtitle: Text('Status: ${r['status']}', style: TextStyle(color: BoostDriveTheme.textDim)),
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
      ),
    );
  }

  List<Map<String, dynamic>> _filteredInventory(List<Map<String, dynamic>> rows, String q) {
    if (q.isEmpty) return rows;
    return rows.where((r) {
      final name = (r['name'] ?? '').toString().toLowerCase();
      final sku = (r['sku'] ?? '').toString().toLowerCase();
      final bc = (r['barcode'] ?? '').toString().toLowerCase();
      return name.contains(q) || sku.contains(q) || bc.contains(q);
    }).toList();
  }

  Widget _summaryCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: BoostDriveTheme.primaryColor, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) {
    return Text(
      t.toUpperCase(),
      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
    );
  }

  Widget _inventoryTile(BuildContext context, String uid, Map<String, dynamic> r) {
    final qty = (r['stock_quantity'] as num?)?.toInt() ?? 0;
    final th = (r['low_stock_threshold'] as num?)?.toInt() ?? 0;
    final low = qty <= th;
    final mobile = r['available_for_mobile'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(low ? Icons.warning_amber : Icons.build_circle_outlined, color: low ? Colors.amber : Colors.white54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    Text(
                      'Qty $qty · threshold $th · ${r['item_category'] ?? 'part'}',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Edit item',
                        icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.white70),
                        onPressed: () => _editInventoryItem(context, uid, r),
                      ),
                      IconButton(
                        tooltip: 'Delete item',
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        onPressed: () => _deleteInventoryItem(context, uid, r),
                      ),
                    ],
                  ),
                  Text('Mobile', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 10)),
                  Switch.adaptive(
                    value: mobile,
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
        ),
      ),
    );
  }

  Future<void> _editInventoryItem(BuildContext context, String uid, Map<String, dynamic> row) async {
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
        backgroundColor: BoostDriveTheme.surfaceDark,
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete item?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete "${row['name'] ?? 'this item'}"?',
          style: TextStyle(color: BoostDriveTheme.textDim),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: BoostDriveTheme.textDim),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _errorBox(String msg) {
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
    final name = TextEditingController();
    final desc = TextEditingController();
    final notes = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
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
    final name = TextEditingController(text: kit['name']?.toString() ?? '');
    final desc = TextEditingController(text: kit['description']?.toString() ?? '');
    final notes = TextEditingController(text: kit['vehicle_notes']?.toString() ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete kit?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${kit['name'] ?? 'this kit'}"?', style: TextStyle(color: BoostDriveTheme.textDim)),
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
    final name = TextEditingController();
    final notes = TextEditingController();
    final status = TextEditingController(text: 'available');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
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
    final name = TextEditingController(text: row['name']?.toString() ?? '');
    final notes = TextEditingController(text: row['notes']?.toString() ?? '');
    final status = TextEditingController(text: row['status']?.toString() ?? 'available');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BoostDriveTheme.surfaceDark,
        title: const Text('Delete equipment?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "${row['name'] ?? 'this equipment'}"?', style: TextStyle(color: BoostDriveTheme.textDim)),
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
