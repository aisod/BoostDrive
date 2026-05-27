import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final palette = DashboardPalette.of(context);
    final uid = ref.watch(currentUserProvider)?.id;
    if (uid == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: Text('Please log in', style: DashboardTypography.bodyMd(palette))),
      );
    }
    final role = ref.watch(mobileShellRoleProvider);
    final canManage = role == 'service_pro' || role == 'logistics';
    if (!canManage) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Service catalog management is available to service providers only.',
              style: DashboardTypography.bodyMd(palette),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final profile = ref.watch(userProfileProvider(uid)).valueOrNull;
    final listAsync = ref.watch(_providerServicesCatalogFamily(uid));

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileProviderUi.glassAppBar(
        context: context,
        palette: palette,
        title: 'BoostDrive',
        avatar: MobileProviderUi.profileAvatar(
          palette: palette,
          imageUrl: profile?.profileImg,
        ),
      ),
      body: Stack(
        children: [
          listAsync.when(
            data: (rows) {
              if (rows.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    MobileProviderUi.marginMobile,
                    16,
                    MobileProviderUi.marginMobile,
                    100,
                  ),
                  children: [
                    MobileProviderUi.pageHeader(
                      palette: palette,
                      title: 'Services Catalog',
                      subtitle: 'Define offerings customers can book. Data syncs to provider_services.',
                    ),
                  ],
                );
              }
              final activeCount = rows.where((r) => r['is_active'] == true).length;
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  MobileProviderUi.marginMobile,
                  12,
                  MobileProviderUi.marginMobile,
                  100,
                ),
                children: [
                  MobileProviderUi.pageHeader(
                    palette: palette,
                    title: 'Services Catalog',
                    subtitle: 'Manage your automotive service offerings and pricing.',
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                    children: [
                      MobileProviderUi.bentoStatCard(
                        palette: palette,
                        label: 'Active',
                        value: '$activeCount',
                        icon: Icons.check_circle_outline,
                      ),
                      MobileProviderUi.bentoStatCard(
                        palette: palette,
                        label: 'Catalog',
                        value: '${rows.length}',
                        icon: Icons.handyman,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...rows.map((r) {
                    final rowId = _serviceRowId(r);
                    final active = r['is_active'] == true;
                    final estMin = r['estimated_minutes'] ?? r['duration_minutes'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: MobileProviderUi.serviceCatalogCard(
                        palette: palette,
                        name: r['name']?.toString() ?? '',
                        category: r['category']?.toString() ?? '',
                        priceLabel: 'N\$${(r['price'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                        durationLabel: '~ $estMin min',
                        description: r['description']?.toString() ?? '',
                        active: active,
                        onActiveChanged: rowId == null
                            ? null
                            : (v) async {
                                try {
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
                        onEdit: rowId == null ? null : () => _openAddSheet(context, ref, uid, existing: r),
                        onDelete: rowId == null
                            ? null
                            : () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: palette.surfaceContainerHigh,
                                    title: Text('Remove service?', style: TextStyle(color: palette.title)),
                                    content: Text(
                                      'This deletes the catalog row.',
                                      style: DashboardTypography.bodyMd(palette),
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
                    );
                  }),
                ],
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
            right: MobileProviderUi.marginMobile,
            bottom: 24,
            child: FloatingActionButton.extended(
              onPressed: () => _openAddSheet(context, ref, uid, existing: null),
              backgroundColor: palette.primaryContainer,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('ADD SERVICE'),
            ),
          ),
        ],
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
    final palette = DashboardPalette.of(context);
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
      backgroundColor: MobileProviderUi.cardSurface(palette),
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
                      style: GoogleFonts.manrope(
                        color: palette.title,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: name,
                      style: TextStyle(color: palette.title),
                      decoration: _fieldDeco(palette, 'Service title'),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: _fieldDeco(palette, 'Category'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: category,
                          dropdownColor: MobileProviderUi.cardSurface(palette),
                          style: TextStyle(color: palette.title),
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
                      style: TextStyle(color: palette.title),
                      decoration: _fieldDeco(palette, 'Description'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: price,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: palette.title),
                            decoration: _fieldDeco(palette, 'Base price'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: minutes,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: palette.title),
                            decoration: _fieldDeco(palette, 'Est. minutes'),
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

  InputDecoration _fieldDeco(DashboardPalette palette, String hint) {
    return MobileProviderUi.fieldDecoration(palette, hint: hint).copyWith(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }
}

final _providerServicesCatalogFamily = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, uid) async {
  return ref.read(providerOpsServiceProvider).listProviderServices(uid);
});
