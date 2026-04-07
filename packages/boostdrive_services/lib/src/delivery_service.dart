import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'providers.dart';

class DeliveryService {
  final _supabase = Supabase.instance.client;

  Stream<List<DeliveryOrder>> getActiveDeliveries(String userId) {
    return _supabase
        .from('delivery_orders')
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((item) =>
                item['customer_id'] == userId ||
                item['seller_id'] == userId ||
                item['driver_id'] == userId)
            .map((json) => DeliveryOrder.fromMap(json))
            .toList());
  }

  Stream<List<DeliveryOrder>> getPendingQueue() {
    return _supabase
        .from('delivery_orders')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .map((data) => data.map((json) => DeliveryOrder.fromMap(json)).toList());
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
    return _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('status', 'completed')
        .map((data) => data.fold(0.0, (sum, item) {
          final amt = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          return sum + amt;
        }));
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
  return Supabase.instance.client
      .from('delivery_orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .map((data) => data.isEmpty ? null : DeliveryOrder.fromMap(data.first));
});
