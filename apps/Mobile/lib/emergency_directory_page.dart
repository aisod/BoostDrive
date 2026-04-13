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
    final lines = <String>[e.phone, if (e.secondaryPhone != null && e.secondaryPhone!.trim().isNotEmpty) e.secondaryPhone!];
    final copyText = lines.join('\n');
    final hasAlt = e.secondaryPhone != null && e.secondaryPhone!.trim().isNotEmpty;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: BoostDriveTheme.surfaceDark,
          title: Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (e.organization != null && e.organization!.isNotEmpty)
                  Text(e.organization!, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
                if (e.organization != null && e.organization!.isNotEmpty) const SizedBox(height: 10),
                ...lines.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(p, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                if (hasAlt)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Call uses the main number first. Use the button below to dial the alternate line.',
                      style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, height: 1.35),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyText));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lines.length > 1 ? 'Numbers copied' : 'Number copied'), backgroundColor: Colors.green.shade700),
                  );
                }
              },
              child: Text(lines.length > 1 ? 'Copy numbers' : 'Copy number'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _launchDialer(e.phone);
              },
              child: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (hasAlt)
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _launchDialer(e.secondaryPhone!);
                },
                child: const Text('Call alternate'),
              ),
          ],
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
    final bundleAsync = ref.watch(emergencyDirectoryBundleProvider);

    return Scaffold(
      backgroundColor: BoostDriveTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Emergency contacts'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: BoostDriveTheme.primaryColor)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Could not load contacts', style: TextStyle(color: BoostDriveTheme.textDim)),
                const SizedBox(height: 12),
                Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(emergencyDirectoryBundleProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search name, region, number…',
                    hintStyle: TextStyle(color: BoostDriveTheme.textDim.withValues(alpha: 0.8)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: BoostDriveTheme.surfaceDark.withValues(alpha: 0.85),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All categories'),
                        selected: _categoryFilter == null,
                        onSelected: (_) => setState(() => _categoryFilter = null),
                        selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.35),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(color: _categoryFilter == null ? Colors.white : BoostDriveTheme.textDim),
                      ),
                    ),
                    ...categories.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_categoryLabel(c)),
                          selected: _categoryFilter == c,
                          onSelected: (_) => setState(() => _categoryFilter = _categoryFilter == c ? null : c),
                          selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.35),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: _categoryFilter == c ? Colors.white : BoostDriveTheme.textDim),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('All regions'),
                        selected: _regionFilter == null,
                        onSelected: (_) => setState(() => _regionFilter = null),
                        selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.35),
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(color: _regionFilter == null ? Colors.white : BoostDriveTheme.textDim),
                      ),
                    ),
                    ...regionCodes.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(regionChipLabel(r)),
                          selected: _regionFilter == r,
                          onSelected: (_) => setState(() => _regionFilter = _regionFilter == r ? null : r),
                          selectedColor: BoostDriveTheme.primaryColor.withValues(alpha: 0.35),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(color: _regionFilter == r ? Colors.white : BoostDriveTheme.textDim),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          entries.isEmpty
                              ? 'No contacts yet. Add rows in Supabase (emergency_directory_entries).'
                              : 'No matches. Try different filters or search.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: BoostDriveTheme.textDim),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (context, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final e = filtered[i];
                          return Material(
                            color: BoostDriveTheme.surfaceDark.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showContactDialog(e),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: BoostDriveTheme.primaryColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            _categoryLabel(e.category),
                                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          e.displayLocality,
                                          style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      e.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    if (e.organization != null && e.organization!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(e.organization!, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 13)),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(e.phone, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                                    if (e.secondaryPhone != null && e.secondaryPhone!.trim().isNotEmpty)
                                      Text(e.secondaryPhone!, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                                    if (e.notes != null && e.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(e.notes!, style: TextStyle(color: BoostDriveTheme.textDim, fontSize: 12, height: 1.3)),
                                    ],
                                  ],
                                ),
                              ),
                            ),
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
