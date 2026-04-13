import 'dart:typed_data';
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
    // This is a more complex query because we need records for ALL vehicles owned by the user.
    // However, the service_history table has provider_id which is NOT the owner_id.
    // We should probably filter by vehicle_id IN (list of vehicle IDs).
    // For now, if provider_id is the user (customer logging their own service), it works.
    // A better way is to join or use a filter if we want records regardless of who logged it.
    return _supabase
        .from('service_history')
        .stream(primaryKey: ['id'])
        .eq('provider_id', userId) // Assuming customers log their own service for now
        .order('completed_at', ascending: false)
        .map((data) => data.map((json) => ServiceRecord.fromMap(json)).toList());
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
