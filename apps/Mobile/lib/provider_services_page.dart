import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'providers.dart';

/// CRUD on `provider_services` (catalog for billing and customer-facing menu).
class ProviderServicesPage extends ConsumerWidget {
  const ProviderServicesPage({super.key});

  static const _categories = [
    'mechanical',
    'electrical',
    'bodywork',
    'diagnostics',
    'towing',
    'other',
  ];

  /// Accepts values like `1200`, `1200.50`, `N$1200`, `N$ 1,200.00`.
  static double _parsePrice(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  static int _parseMinutes(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return 60;
    return int.tryParse(cleaned) ?? 60;
  }

  /// Primary key for Supabase updates; supports legacy column names on read.
  static String? _serviceRowId(Map<String, dynamic>? row) {
    if (row == null) return null;
    final v = row['id'] ?? row['service_id'] ?? row['provider_service_id'];
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty || s == 'null') return null;
    return s;
  }

  static String _formatServiceSaveError(Object e) {
    String code = '';
    var msg = e.toString().toLowerCase();
    if (e is PostgrestException) {
      code = e.code ?? '';
      msg = e.message.toLowerCase();
    } else {
      try {
        final d = e as dynamic;
        code = d.code?.toString() ?? '';
        msg = (d.message ?? '$e').toString().toLowerCase();
      } catch (_) {}
    }
    if (code == '23505' || msg.contains('duplicate key') || msg.contains('unique constraint')) {
      return 'That service (or a very similar row) already exists for your account. '
          'If you tapped Save more than once, check the list — or pick a different title.';
    }
    return '$e';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Provider ID is required to scope catalog rows.
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) {
      return const Center(child: Text('Please log in'));
    }
    final role = ref.watch(mobileShellRoleProvider);
    final canManage = role == 'service_pro' || role == 'logistics';
    if (!canManage) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Service catalog management is available to service providers only.',
            style: TextStyle(color: BoostDriveTheme.textDim, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Load provider service catalog from backend.
    final listAsync = ref.watch(_providerServicesCatalogFamily(uid));

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: BoostDriveTheme.backgroundDark,
      child: SafeArea(
        child: Stack(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  'SERVICES',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          listAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                // Empty state when provider has no services yet.
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
                  children: [
                    Text(
                      'Define offerings customers can book. Data syncs to provider_services.',
                      style: TextStyle(color: BoostDriveTheme.textDim, height: 1.4),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
                itemCount: rows.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final r = rows[index];
                  // Resolve row id using modern and legacy keys.
                  final rowId = _serviceRowId(r);
                  final active = r['is_active'] == true;
                  final estMin = r['estimated_minutes'] ?? r['duration_minutes'] ?? 0;
                  return Material(
                    color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  r['name']?.toString() ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text('Active', style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11)),
                              Switch.adaptive(
                                value: active,
                                onChanged: rowId == null
                                    ? null
                                    : (v) async {
                                        try {
                                          // Persist active flag change.
                                          await ref.read(providerOpsServiceProvider).updateProviderServiceActive(
                                                id: rowId,
                                                isActive: v,
                                              );
                                          ref.invalidate(_providerServicesCatalogFamily(uid));
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                          }
                                        }
                                      },
                              ),
                            ],
                          ),
                          Text(
                            r['category']?.toString() ?? '',
                            style: TextStyle(color: BoostDriveTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r['description']?.toString() ?? '',
                            style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13, height: 1.35),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'N\$${(r['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '~ $estMin min',
                                style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13),
                              ),
                              const Spacer(),
                              IconButton(
                                tooltip: rowId == null ? 'Missing service id — fix table in Supabase' : 'Edit',
                                icon: Icon(Icons.edit_outlined, color: rowId == null ? Colors.white24 : Colors.white70),
                                onPressed: rowId == null
                                    ? null
                                    : () => _openAddSheet(context, ref, uid, existing: r),
                              ),
                              IconButton(
                                tooltip: rowId == null ? 'Missing service id' : 'Delete',
                                icon: Icon(Icons.delete_outline, color: rowId == null ? Colors.white24 : Colors.white38),
                                onPressed: rowId == null
                                    ? null
                                    : () async {
                                  // Confirm deletion before removing service row.
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: BoostDriveTheme.surfaceDark,
                                      title: const Text('Remove service?', style: TextStyle(color: Colors.white)),
                                      content: const Text(
                                        'This deletes the catalog row.',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('DELETE')),
                                      ],
                                    ),
                                  );
                                  if (ok == true && context.mounted) {
                                    try {
                                      await ref.read(providerOpsServiceProvider).deleteProviderService(rowId);
                                      ref.invalidate(_providerServicesCatalogFamily(uid));
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          if (rowId == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'This row has no id in the API response. Add a uuid primary key column `id` in Supabase, then refresh.',
                                style: TextStyle(color: Colors.orange.shade200, fontSize: 11, height: 1.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Could not load provider_services.\n$e',
                  style: TextStyle(color: Colors.red.shade200),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: () => _openAddSheet(context, ref, uid, existing: null),
              backgroundColor: BoostDriveTheme.primaryColor,
              icon: const Icon(Icons.add),
              label: const Text('ADD SERVICE'),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    String uid, {
    required Map<String, dynamic>? existing,
  }) async {
    // Keep messenger from parent context so feedback still works after modal closes.
    final messenger = ScaffoldMessenger.of(context);
    var isSubmitting = false;
    final name = TextEditingController(text: existing?['name']?.toString() ?? '');
    final desc = TextEditingController(text: existing?['description']?.toString() ?? '');
    final priceNum = existing?['price'];
    final price = TextEditingController(
      text: priceNum is num ? priceNum.toString() : (existing == null ? '0' : ''),
    );
    final minutes = TextEditingController(
      text: (existing?['estimated_minutes'] ?? existing?['duration_minutes'] ?? 60).toString(),
    );
    final existingId = _serviceRowId(existing);
    final rawCat = existing?['category']?.toString();
    String category = (rawCat != null && _categories.contains(rawCat)) ? rawCat : _categories.first;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BoostDriveTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSt) {
              // Local sheet state handles submit loading button.
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existingId == null ? 'New service' : 'Edit service',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: name,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDeco('Service title'),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: _fieldDeco('Category'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: category,
                          dropdownColor: BoostDriveTheme.surfaceDark,
                          style: const TextStyle(color: Colors.white),
                          items: _categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setSt(() => category = v ?? category),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: desc,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: _fieldDeco('Description'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: price,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDeco('Base price'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minutes,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: _fieldDeco('Est. minutes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (name.text.trim().isEmpty) {
                                messenger.showSnackBar(const SnackBar(content: Text('Please enter a service title')));
                                return;
                              }
                              if (existing != null && existingId == null) {
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Cannot edit: this row has no id. Fix provider_services primary key in Supabase.'),
                                  ),
                                );
                                return;
                              }
                              setSt(() => isSubmitting = true);
                              try {
                                final parsedPrice = _parsePrice(price.text);
                                final parsedMinutes = _parseMinutes(minutes.text);
                                final ops = ref.read(providerOpsServiceProvider);
                                if (existingId == null) {
                                  // Create new service row.
                                  await ops.insertProviderService(
                                    providerId: uid,
                                    name: name.text.trim(),
                                    category: category,
                                    description: desc.text.trim(),
                                    price: parsedPrice,
                                    estimatedMinutes: parsedMinutes,
                                  );
                                } else {
                                  // Update existing service row.
                                  await ops.updateProviderService(
                                    id: existingId,
                                    name: name.text.trim(),
                                    category: category,
                                    description: desc.text.trim(),
                                    price: parsedPrice,
                                    estimatedMinutes: parsedMinutes,
                                  );
                                }
                                ref.invalidate(_providerServicesCatalogFamily(uid));
                                if (ctx.mounted) Navigator.pop(ctx, true);
                              } catch (e) {
                                messenger.showSnackBar(SnackBar(content: Text(_formatServiceSaveError(e))));
                              } finally {
                                if (ctx.mounted) setSt(() => isSubmitting = false);
                              }
                            },
                      child: Text(isSubmitting ? 'SAVING…' : 'SAVE'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (ok == true && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(existingId == null ? 'Service added' : 'Service updated')),
      );
    }
  }

  InputDecoration _fieldDeco(String hint) {
    // Shared field style for bottom-sheet inputs.
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: BoostDriveTheme.textDim),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

final _providerServicesCatalogFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listProviderServices(uid);
});
