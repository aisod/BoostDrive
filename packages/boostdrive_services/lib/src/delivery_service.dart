import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'dart:async';
import 'providers.dart';

class DeliveryService {
  final _supabase = Supabase.instance.client;

  Stream<List<DeliveryOrder>> getActiveDeliveries(String userId) {
    final realtime = _supabase
        .from('delivery_orders')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((item) =>
                item['customer_id'] == userId ||
                item['seller_id'] == userId ||
                item['driver_id'] == userId)
            .map((json) => DeliveryOrder.fromMap(json))
            .toList());
    return _withPollingFallback(
      realtime,
      () => _fetchActiveDeliveriesSnapshot(userId),
      label: 'getActiveDeliveries',
      interval: const Duration(seconds: 6),
    );
  }

  Stream<List<DeliveryOrder>> getPendingQueue() {
    final realtime = _supabase
        .from('delivery_orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((data) => data.map((json) => DeliveryOrder.fromMap(json)).toList());
    return _withPollingFallback(
      realtime,
      _fetchPendingQueueSnapshot,
      label: 'getPendingQueue',
    );
  }

  Future<void> updateDeliveryStatus(String orderId, String status, {String? eta, String? driverId}) async {
    final updates = {
      'status': status,
    };
    if (eta != null) updates['eta'] = eta;
    if (driverId != null) updates['driver_id'] = driverId;

    await _supabase.from('delivery_orders').update(updates).eq('id', orderId);
  }

  Stream<double> getGlobalVolume() {
    final realtime = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('status', 'completed')
        .map((data) => data.fold(0.0, (sum, item) {
          final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          return sum + amt;
        }));
    return _withPollingFallback(
      realtime,
      _fetchGlobalVolumeSnapshot,
      label: 'getGlobalVolume',
    );
  }

  Stream<DeliveryOrder?> streamSingleDelivery(String orderId) {
    final realtime = _supabase
        .from('delivery_orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .map((data) => data.isEmpty ? null : DeliveryOrder.fromMap(data.first));
    return _withPollingFallback(
      realtime,
      () => _fetchSingleDeliverySnapshot(orderId),
      label: 'streamSingleDelivery',
      interval: const Duration(seconds: 6),
    );
  }

  Stream<T> _withPollingFallback<T>(
    Stream<T> realtime,
    Future<T> Function() fetchSnapshot, {
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
      }
      await Future<void>.delayed(interval);
    }
  }

  Future<List<DeliveryOrder>> _fetchActiveDeliveriesSnapshot(String userId) async {
    final rows = await _supabase
        .from('delivery_orders')
        .select()
        .or('customer_id.eq.$userId,seller_id.eq.$userId,driver_id.eq.$userId');
    return (rows as List<dynamic>)
        .map((json) => DeliveryOrder.fromMap(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<List<DeliveryOrder>> _fetchPendingQueueSnapshot() async {
    final rows = await _supabase
        .from('delivery_orders')
        .select()
        .eq('status', 'pending');
    return (rows as List<dynamic>)
        .map((json) => DeliveryOrder.fromMap(Map<String, dynamic>.from(json as Map)))
        .toList();
  }

  Future<double> _fetchGlobalVolumeSnapshot() async {
    final rows = await _supabase
        .from('transactions')
        .select('amount')
        .eq('status', 'completed');
    return (rows as List<dynamic>).fold<double>(0.0, (sum, item) {
      final row = Map<String, dynamic>.from(item as Map);
      final amt = double.tryParse(row['amount']?.toString() ?? '0') ?? 0.0;
      return sum + amt;
    });
  }

  Future<DeliveryOrder?> _fetchSingleDeliverySnapshot(String orderId) async {
    final row = await _supabase
        .from('delivery_orders')
        .select()
        .eq('id', orderId)
        .maybeSingle();
    if (row == null) return null;
    return DeliveryOrder.fromMap(Map<String, dynamic>.from(row));
  }
}

final deliveryServiceProvider = Provider<DeliveryService>((ref) {
  return DeliveryService();
});

final activeDeliveriesProvider = StreamProvider.family<List<DeliveryOrder>, String>((ref, userId) {
  // Watch the refresh trigger for manual updates
  ref.watch(dashboardRefreshProvider);
  
  // Add 20-second polling fallback for external status changes
  // ignore: unused_local_variable
  final keepAlive = Stream.periodic(const Duration(seconds: 20)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => keepAlive.cancel());

  return ref.watch(deliveryServiceProvider).getActiveDeliveries(userId);
});

final globalVolumeProvider = StreamProvider<double>((ref) {
  return ref.watch(deliveryServiceProvider).getGlobalVolume();
});

final singleDeliveryProvider = StreamProvider.family<DeliveryOrder?, String>((ref, orderId) {
  return ref.watch(deliveryServiceProvider).streamSingleDelivery(orderId);
});
