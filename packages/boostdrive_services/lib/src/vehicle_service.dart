import 'dart:typed_data';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'providers.dart';

class VehicleService {
  final _supabase = Supabase.instance.client;

  Stream<List<Vehicle>> getUserVehicles(String ownerId) {
    final realtime = _supabase
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .eq('owner_id', ownerId)
        .order('created_at')
        .map((data) => data.map((json) => Vehicle.fromMap(json)).toList());
    return _withPollingFallback(
      realtime,
      () => _fetchUserVehiclesSnapshot(ownerId),
      label: 'getUserVehicles',
      interval: const Duration(seconds: 6),
    );
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    await _supabase.from('vehicles').insert(vehicle.toMap());
  }

  Future<String?> uploadVehicleImage(String userId, Uint8List bytes, String fileName) async {
    try {
      final sanitizedFileName = fileName.replaceAll(' ', '_');
      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      print("DEBUG: Uploading to vehicles/$path...");
      await _supabase.storage.from('vehicles').uploadBinary(path, bytes);
      final url = _supabase.storage.from('vehicles').getPublicUrl(path);
      print("DEBUG: Upload success. URL: $url");
      return url;
    } catch (e) {
      print("DEBUG: Storage Upload Error (Check if 'vehicles' bucket exists and is public): $e");
      rethrow;
    }
  }

  Future<void> updateVehicleHealth(String vehicleId, String status, String fuel) async {
    await _supabase.from('vehicles').update({
      'health_status': status,
      'fuel_level': fuel,
    }).eq('id', vehicleId);
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    await _supabase.from('vehicles').update(vehicle.toMap()).eq('id', vehicle.id);
  }

  Future<void> deleteVehicle(String vehicleId) async {
    await _supabase.from('vehicles').delete().eq('id', vehicleId);
  }

  Stream<List<Vehicle>> _withPollingFallback(
    Stream<List<Vehicle>> realtime,
    Future<List<Vehicle>> Function() fetchSnapshot, {
    required String label,
    Duration interval = const Duration(seconds: 8),
  }) async* {
    try {
      yield* realtime;
      return;
    } catch (e) {
      print('DEBUG: $label realtime failed, switching to polling: $e');
    }

    while (true) {
      try {
        yield await fetchSnapshot();
      } catch (e) {
        print('DEBUG: $label polling fetch failed: $e');
        yield const <Vehicle>[];
      }
      await Future<void>.delayed(interval);
    }
  }

  Future<List<Vehicle>> _fetchUserVehiclesSnapshot(String ownerId) async {
    final rows = await _supabase
        .from('vehicles')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((json) => Vehicle.fromMap(Map<String, dynamic>.from(json as Map)))
        .toList();
  }
}

final vehicleServiceProvider = Provider<VehicleService>((ref) {
  return VehicleService();
});

final userVehiclesProvider = StreamProvider.family<List<Vehicle>, String>((ref, userId) {
  // Watch the refresh trigger to force re-fetch when it changes
  ref.watch(dashboardRefreshProvider);
  return ref.watch(vehicleServiceProvider).getUserVehicles(userId);
});
