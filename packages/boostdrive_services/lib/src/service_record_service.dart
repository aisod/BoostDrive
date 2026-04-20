import 'dart:typed_data';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'providers.dart';

class ServiceRecordService {
  final _supabase = Supabase.instance.client;

  Stream<List<ServiceRecord>> getVehicleServiceHistory(String vehicleId) {
    return _supabase
        .from('service_history')
        .stream(primaryKey: ['id'])
        .eq('vehicle_id', vehicleId)
        .order('completed_at', ascending: false)
        .map((data) => data.map((json) => ServiceRecord.fromMap(json)).toList());
  }

  Stream<List<ServiceRecord>> getProviderHistory(String providerId) {
    return _supabase
        .from('service_history')
        .stream(primaryKey: ['id'])
        .eq('provider_id', providerId)
        .order('completed_at', ascending: false)
        .map((data) => data.map((json) => ServiceRecord.fromMap(json)).toList());
  }

  Future<void> addServiceRecord(ServiceRecord record) async {
    await _supabase.from('service_history').insert(record.toMap());
  }

  Future<String?> uploadServiceReceipt(String vehicleId, Uint8List bytes, String fileName) async {
    try {
      final sanitizedFileName = fileName.replaceAll(' ', '_');
      final path = '$vehicleId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      await _supabase.storage.from('service_receipts').uploadBinary(path, bytes);
      return _supabase.storage.from('service_receipts').getPublicUrl(path);
    } catch (e) {
      print("DEBUG: Storage Upload Error (Check if 'service_receipts' bucket exists and is public): $e");
      rethrow;
    }
  }

  Future<void> updateServiceRecord(ServiceRecord record) async {
    await _supabase.from('service_history').update(record.toMap()).eq('id', record.id);
  }

  Future<void> deleteServiceRecord(String recordId) async {
    await _supabase.from('service_history').delete().eq('id', recordId);
  }

  /// All service records for any of the given vehicles (garage-wide history).
  Future<List<ServiceRecord>> fetchHistoryForVehicleIds(List<String> vehicleIds) async {
    if (vehicleIds.isEmpty) return [];
    try {
      final response = await _supabase
          .from('service_history')
          .select()
          .inFilter('vehicle_id', vehicleIds)
          .order('completed_at', ascending: false);
      final list = response as List;
      return list.map((json) => ServiceRecord.fromMap(Map<String, dynamic>.from(json as Map))).toList();
    } catch (e) {
      print('DEBUG: fetchHistoryForVehicleIds error: $e');
      return [];
    }
  }

  Stream<List<ServiceRecord>> getUserServiceHistory(String userId) {
    // Primary path: realtime stream for instant updates.
    final realtime = _supabase
        .from('service_history')
        .stream(primaryKey: ['id'])
        .eq('provider_id', userId)
        .order('completed_at', ascending: false)
        .map((data) => data.map((json) => ServiceRecord.fromMap(json)).toList());

    // Fallback path: if realtime socket is unavailable (e.g. flaky DNS/network),
    // switch to polling so the page stays usable instead of showing a hard error.
    return _withPollingFallback(userId, realtime);
  }

  Stream<List<ServiceRecord>> _withPollingFallback(
    String userId,
    Stream<List<ServiceRecord>> realtime,
  ) async* {
    try {
      yield* realtime;
      return;
    } catch (e) {
      print('DEBUG: getUserServiceHistory realtime failed, switching to polling: $e');
    }

    while (true) {
      try {
        yield await _fetchUserServiceHistorySnapshot(userId);
      } catch (e) {
        print('DEBUG: getUserServiceHistory polling fetch failed: $e');
        yield const <ServiceRecord>[];
      }
      await Future<void>.delayed(const Duration(seconds: 8));
    }
  }

  Future<List<ServiceRecord>> _fetchUserServiceHistorySnapshot(String userId) async {
    final response = await _supabase
        .from('service_history')
        .select()
        .eq('provider_id', userId)
        .order('completed_at', ascending: false);
    final list = response as List<dynamic>;
    return list
        .map((json) => ServiceRecord.fromMap(Map<String, dynamic>.from(json as Map)))
        .toList();
  }
}

final serviceRecordServiceProvider = Provider<ServiceRecordService>((ref) {
  return ServiceRecordService();
});

final vehicleHistoryProvider = StreamProvider.family<List<ServiceRecord>, String>((ref, vehicleId) {
  // Watch the refresh trigger to force re-fetch when it changes
  ref.watch(dashboardRefreshProvider);
  return ref.watch(serviceRecordServiceProvider).getVehicleServiceHistory(vehicleId);
});

final userServiceHistoryProvider = StreamProvider.family<List<ServiceRecord>, String>((ref, userId) {
  // Watch the refresh trigger to force re-fetch when it changes
  ref.watch(dashboardRefreshProvider);
  return ref.watch(serviceRecordServiceProvider).getUserServiceHistory(userId);
});
