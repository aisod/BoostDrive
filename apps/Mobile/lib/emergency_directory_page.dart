import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Searchable Namibia-focused emergency and roadside directory (Supabase-backed).
class EmergencyDirectoryPage extends ConsumerStatefulWidget {
  const EmergencyDirectoryPage({super.key});

  @override
  ConsumerState<EmergencyDirectoryPage> createState() => _EmergencyDirectoryPageState();
}

class _EmergencyDirectoryPageState extends ConsumerState<EmergencyDirectoryPage> {
  final TextEditingController _search = TextEditingController();

  String? _categoryFilter;
  String? _regionFilter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static String _categoryLabel(String key) {
    switch (key) {
      case 'police':
        return 'Police';
      case 'ambulance':
        return 'Ambulance';
      case 'towing':
        return 'Towing';
      case 'mobile_mechanic':
        return 'Mobile mechanic';
      case 'fuel_refill':
        return 'Fuel refill';
      case 'flat_tire':
        return 'Flat tire';
      case 'accident':
        return 'Accident';
      default:
        return 'Other';
    }
  }

  static String _regionLabel(String key) {
    if (key == 'national') return 'National';
    return key.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  static String _digitsForTel(String raw) {
    final b = StringBuffer();
    for (final c in raw.runes) {
      final ch = String.fromCharCode(c);
      if (ch == '+' || (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39)) {
        b.write(ch);
      }
    }
    return b.toString();
  }

  static Future<void> _launchDialer(String phone) async {
    final cleaned = _digitsForTel(phone);
    if (cleaned.isEmpty) return;
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _showContactDialog(EmergencyDirectoryEntry e) async {
    final palette = DashboardPalette.of(context);
    final lines = <String>[e.phone, if (e.secondaryPhone != null && e.secondaryPhone!.trim().isNotEmpty) e.secondaryPhone!];
    final copyText = lines.join('\n');
    final hasAlt = e.secondaryPhone != null && e.secondaryPhone!.trim().isNotEmpty;

    await showDialog<void>(
      context: context,
      barrierColor: palette.isDark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.2),
      builder: (ctx) {
        return EmergencyDirectoryUi.contactDetailDialog(
          palette: palette,
          categoryKey: e.category,
          title: e.title,
          organization: e.organization,
          primaryPhone: e.phone,
          secondaryPhone: e.secondaryPhone,
          notes: e.notes,
          onClose: () => Navigator.pop(ctx),
          onCopy: () async {
            await Clipboard.setData(ClipboardData(text: copyText));
            if (ctx.mounted) Navigator.pop(ctx);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lines.length > 1 ? 'Numbers copied' : 'Number copied'),
                  backgroundColor: Colors.green.shade700,
                ),
              );
            }
          },
          onCallPrimary: () async {
            Navigator.pop(ctx);
            await _launchDialer(e.phone);
          },
          onCallAlternate: hasAlt
              ? () async {
                  Navigator.pop(ctx);
                  await _launchDialer(e.secondaryPhone!);
                }
              : null,
        );
      },
    );
  }

  List<EmergencyDirectoryEntry> _applyFilters(
    List<EmergencyDirectoryEntry> all,
    Map<String, NamibiaLocation> byCode,
  ) {
    final q = _search.text.trim().toLowerCase();
    String regionName(String code) => byCode[code]?.name ?? _regionLabel(code);
    String localityName(String code) => byCode[code]?.name ?? _regionLabel(code);
    return all.where((e) {
      if (_categoryFilter != null && e.category != _categoryFilter) return false;
      if (_regionFilter != null && e.effectiveRegionCode != _regionFilter) return false;
      if (q.isEmpty) return true;
      final hay = [
        e.title,
        e.phone,
        e.secondaryPhone ?? '',
        e.displayLocality,
        e.locationCode,
        localityName(e.locationCode),
        e.effectiveRegionCode,
        regionName(e.effectiveRegionCode),
        e.organization ?? '',
        e.notes ?? '',
        e.category,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = DashboardPalette.of(context);
    final bundleAsync = ref.watch(emergencyDirectoryBundleProvider);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: EmergencyDirectoryUi.appBar(context, palette),
      body: bundleAsync.when(
        loading: () => EmergencyDirectoryUi.loadingState(palette),
        error: (e, _) => EmergencyDirectoryUi.errorState(
          palette: palette,
          message: '$e',
          onRetry: () => ref.invalidate(emergencyDirectoryBundleProvider),
        ),
        data: (bundle) {
          final entries = bundle.entries;
          final byCode = {for (final l in bundle.locations) l.code: l};
          final categories = entries.map((e) => e.category).toSet().toList()..sort();
          final regionCodes = entries.map((e) => e.effectiveRegionCode).toSet().toList()
            ..sort((a, b) {
              final la = byCode[a];
              final lb = byCode[b];
              final oa = la?.sortOrder ?? 9999;
              final ob = lb?.sortOrder ?? 9999;
              if (oa != ob) return oa.compareTo(ob);
              return (la?.name ?? a).compareTo(lb?.name ?? b);
            });
          String regionChipLabel(String code) => byCode[code]?.name ?? _regionLabel(code);

          final filtered = _applyFilters(entries, byCode);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: EmergencyDirectoryUi.pageHeader(palette)),
              SliverToBoxAdapter(
                child: EmergencyDirectoryUi.searchField(
                  palette: palette,
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              SliverToBoxAdapter(
                child: EmergencyDirectoryUi.filterSectionLabel(palette, 'Categories'),
              ),
              SliverToBoxAdapter(
                child: EmergencyDirectoryUi.categoryChipRow(
                  palette: palette,
                  children: [
                    EmergencyDirectoryUi.categoryChip(
                      palette: palette,
                      label: 'All',
                      categoryKey: '__all__',
                      selected: _categoryFilter == null,
                      onTap: () => setState(() => _categoryFilter = null),
                    ),
                    ...categories.map(
                      (c) => EmergencyDirectoryUi.categoryChip(
                        palette: palette,
                        label: _categoryLabel(c),
                        categoryKey: c,
                        selected: _categoryFilter == c,
                        onTap: () => setState(() => _categoryFilter = _categoryFilter == c ? null : c),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: EmergencyDirectoryUi.filterSectionLabel(palette, 'Regions'),
              ),
              SliverToBoxAdapter(
                child: EmergencyDirectoryUi.regionChipRow(
                  palette: palette,
                  children: [
                    EmergencyDirectoryUi.regionChip(
                      palette: palette,
                      label: 'All regions',
                      selected: _regionFilter == null,
                      onTap: () => setState(() => _regionFilter = null),
                    ),
                    ...regionCodes.map(
                      (r) => EmergencyDirectoryUi.regionChip(
                        palette: palette,
                        label: regionChipLabel(r),
                        selected: _regionFilter == r,
                        onTap: () => setState(() => _regionFilter = _regionFilter == r ? null : r),
                      ),
                    ),
                  ],
                ),
              ),
              if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmergencyDirectoryUi.emptyState(
                    palette: palette,
                    message: entries.isEmpty
                        ? 'No contacts yet. Add rows in Supabase (emergency_directory_entries).'
                        : 'No matches. Try different filters or search.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    EmergencyDirectoryUi.marginMobile,
                    16,
                    EmergencyDirectoryUi.marginMobile,
                    32,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 24),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      return EmergencyDirectoryUi.contactCard(
                        palette: palette,
                        categoryKey: e.category,
                        categoryLabel: _categoryLabel(e.category),
                        locality: e.displayLocality,
                        title: e.title,
                        organization: e.organization,
                        phone: e.phone,
                        secondaryPhone: e.secondaryPhone,
                        notes: e.notes,
                        onTap: () => _showContactDialog(e),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
