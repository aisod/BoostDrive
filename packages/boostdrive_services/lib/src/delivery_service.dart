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

  /// Pending unassigned orders plus all orders assigned to this logistics driver.
  Stream<List<DeliveryOrder>> getLogisticsOrders(String logisticsUserId) {
    final realtime = _supabase.from('delivery_orders').stream(primaryKey: ['id']).map((data) {
      return _mergeLogisticsOrders(
        data.map((json) => DeliveryOrder.fromMap(json)).toList(),
        logisticsUserId,
      );
    });
    return _withPollingFallback(
      realtime,
      () async {
        final rows = await _supabase.from('delivery_orders').select();
        return _mergeLogisticsOrders(
          (rows as List<dynamic>)
              .map((json) => DeliveryOrder.fromMap(Map<String, dynamic>.from(json as Map)))
              .toList(),
          logisticsUserId,
        );
      },
      label: 'getLogisticsOrders',
      interval: const Duration(seconds: 6),
    );
  }

  List<DeliveryOrder> _mergeLogisticsOrders(List<DeliveryOrder> all, String logisticsUserId) {
    final pending = all.where((o) {
      final unassigned = o.driverId == null || o.driverId!.trim().isEmpty;
      return o.status == 'pending' && unassigned;
    });
    final mine = all.where((o) => o.driverId == logisticsUserId);
    final byId = <String, DeliveryOrder>{};
    for (final o in [...pending, ...mine]) {
      byId[o.id] = o;
    }
    final list = byId.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Stream<List<DeliveryOrder>> getPendingQueue() {
    final realtime = _supabase
        .from('delivery_orders')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .map((json) => DeliveryOrder.fromMap(json))
            .where((o) => o.status == 'pending' && (o.driverId == null || o.driverId!.trim().isEmpty))
            .toList());
    return _withPollingFallback(
      realtime,
      _fetchPendingQueueSnapshot,
      label: 'getPendingQueue',
    );
  }

  Future<void> assignOrderToDriver({
    required String orderId,
    required String driverId,
    String? eta,
    String? vehicleId,
  }) async {
    await updateDeliveryStatus(
      orderId,
      'picking_up',
      driverId: driverId,
      eta: eta ?? '30 min',
      vehicleId: vehicleId,
    );
  }

  Future<void> updateDeliveryStatus(
    String orderId,
    String status, {
    String? eta,
    String? driverId,
    String? vehicleId,
  }) async {
    final updates = <String, dynamic>{
      'status': status,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (eta != null) updates['eta'] = eta;
    if (driverId != null) updates['driver_id'] = driverId;
    if (vehicleId != null) updates['vehicle_id'] = vehicleId;

    await _supabase.from('delivery_orders').update(updates).eq('id', orderId);
  }

  Future<void> updateDriverLocation(String orderId, double lat, double lng) async {
    await _supabase.from('delivery_orders').update({
      'driver_last_lat': lat,
      'driver_last_lng': lng,
      'driver_location_updated_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', orderId);
  }

  Future<LogisticsFinanceSummary> getLogisticsFinanceSummary(String driverId) async {
    final rows = await _supabase
        .from('delivery_orders')
        .select()
        .eq('driver_id', driverId);
    final orders = (rows as List<dynamic>)
        .map((json) => DeliveryOrder.fromMap(Map<String, dynamic>.from(json as Map)))
        .toList();

    double sumFees(List<DeliveryOrder> list) =>
        list.fold(0.0, (sum, o) => sum + (o.deliveryFee ?? 0));

    final completed = orders.where((o) => o.status == 'delivered').toList();
    final active = orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();
    final cancelled = orders.where((o) => o.status == 'cancelled').toList();
    final inTransit = orders.where((o) => o.status == 'in_transit' || o.status == 'picking_up').toList();

    completed.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final periodCompleted =
        completed.where((o) => o.createdAt.isAfter(monthStart)).toList();

    double profileEarnings = 0;
    try {
      final profile = await _supabase.from('profiles').select('total_earnings').eq('id', driverId).maybeSingle();
      if (profile != null) {
        profileEarnings = double.tryParse(profile['total_earnings']?.toString() ?? '0') ?? 0;
      }
    } catch (_) {}

    final feeTotal = sumFees(completed);
    final lifetime = profileEarnings > 0 ? profileEarnings : feeTotal;

    return LogisticsFinanceSummary(
      lifetimeEarnings: lifetime,
      periodEarnings: sumFees(periodCompleted),
      pendingPayouts: sumFees(inTransit),
      completedCount: completed.length,
      activeCount: active.length,
      cancelledCount: cancelled.length,
      recentCompleted: completed.take(10).toList(),
    );
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
    final rows = await _supabase.from('delivery_orders').select().eq('status', 'pending');
    return (rows as List<dynamic>)
        .map((json) => DeliveryOrder.fromMap(Map<String, dynamic>.from(json as Map)))
        .where((o) => o.driverId == null || o.driverId!.trim().isEmpty)
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
  ref.watch(dashboardRefreshProvider);
  final keepAlive = Stream.periodic(const Duration(seconds: 20)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => keepAlive.cancel());

  return ref.watch(deliveryServiceProvider).getActiveDeliveries(userId);
});

/// All orders visible to a BaTLorriH logistics driver (pending queue + assigned).
final logisticsOrdersProvider = StreamProvider.family<List<DeliveryOrder>, String>((ref, userId) {
  ref.watch(dashboardRefreshProvider);
  final keepAlive = Stream.periodic(const Duration(seconds: 20)).listen((_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => keepAlive.cancel());
  return ref.watch(deliveryServiceProvider).getLogisticsOrders(userId);
});

final logisticsFinanceProvider = FutureProvider.family<LogisticsFinanceSummary, String>((ref, userId) {
  ref.watch(dashboardRefreshProvider);
  return ref.watch(deliveryServiceProvider).getLogisticsFinanceSummary(userId);
});

final globalVolumeProvider = StreamProvider<double>((ref) {
  return ref.watch(deliveryServiceProvider).getGlobalVolume();
});

final singleDeliveryProvider = StreamProvider.family<DeliveryOrder?, String>((ref, orderId) {
  return ref.watch(deliveryServiceProvider).streamSingleDelivery(orderId);
});
