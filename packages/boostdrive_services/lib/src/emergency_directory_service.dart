import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:boostdrive_core/boostdrive_core.dart';

/// Locations + entries loaded together (one round-trip for locations, one for entries).
typedef EmergencyDirectoryBundle = ({List<NamibiaLocation> locations, List<EmergencyDirectoryEntry> entries});

/// Loads public emergency / roadside contacts and Namibia location reference rows from Supabase.
class EmergencyDirectoryService {
  EmergencyDirectoryService(this._client);

  final SupabaseClient _client;

  Future<List<NamibiaLocation>> fetchNamibiaLocations() async {
    try {
      final response = await _client
          .from('namibia_locations')
          .select()
          .order('sort_order', ascending: true)
          .order('name', ascending: true);

      final list = response as List<dynamic>? ?? [];
      return list
          .map((row) => NamibiaLocation.fromMap(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<EmergencyDirectoryEntry>> fetchActiveEntriesWithLocations(List<NamibiaLocation> locations) async {
    try {
      final byCode = {for (final l in locations) l.code: l};

      final response = await _client
          .from('emergency_directory_entries')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('title', ascending: true);

      final list = response as List<dynamic>? ?? [];
      return list.map((row) {
        final m = Map<String, dynamic>.from(row as Map);
        final code = m['location_code']?.toString();
        final loc = code != null ? byCode[code] : null;
        return EmergencyDirectoryEntry.fromMap(m, location: loc);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<EmergencyDirectoryBundle> fetchDirectoryBundle() async {
    final locations = await fetchNamibiaLocations();
    final entries = await fetchActiveEntriesWithLocations(locations);
    return (locations: locations, entries: entries);
  }
}

final emergencyDirectoryServiceProvider = Provider<EmergencyDirectoryService>((ref) {
  return EmergencyDirectoryService(Supabase.instance.client);
});

/// Single load: locations for chips + enriched entries (shared by derived providers below).
final emergencyDirectoryBundleProvider = FutureProvider<EmergencyDirectoryBundle>((ref) {
  return ref.watch(emergencyDirectoryServiceProvider).fetchDirectoryBundle();
});

final namibiaLocationsProvider = FutureProvider<List<NamibiaLocation>>((ref) async {
  return (await ref.watch(emergencyDirectoryBundleProvider.future)).locations;
});

final emergencyDirectoryEntriesProvider = FutureProvider<List<EmergencyDirectoryEntry>>((ref) async {
  return (await ref.watch(emergencyDirectoryBundleProvider.future)).entries;
});
