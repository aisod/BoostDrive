import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Mobile Garage tab — same sections, layout patterns, and dialogs as the web customer dashboard garage.
class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in', style: TextStyle(color: Colors.white))),
      );
    }

    final uid = user.id;

    return PremiumPageLayout(
      showBackground: true,
      appBar: AppBar(
        backgroundColor: BoostDriveTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'My Garage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
            icon: const Icon(Icons.add_circle, size: 20, color: Colors.white),
            label: const Text('Add Vehicle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomerGarageSectionHeader(title: 'My Garage', icon: Icons.directions_car),
              const SizedBox(height: 24),
              _GarageVehiclesBlock(uid: uid),
              const SizedBox(height: 48),
              const CustomerGarageSectionHeader(title: 'Active Orders', icon: Icons.local_shipping),
              const SizedBox(height: 24),
              _GarageOrdersBlock(uid: uid),
              const SizedBox(height: 48),
              const CustomerGarageSectionHeader(title: 'Service History', icon: Icons.history),
              const SizedBox(height: 24),
              _GarageServiceHistoryBlock(uid: uid),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarageVehiclesBlock extends ConsumerWidget {
  const _GarageVehiclesBlock({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No vehicles found in your garage.', style: TextStyle(color: BoostDriveTheme.textDim)),
                  const SizedBox(height: 16),
                  CustomerGarageAddButton(
                    label: 'Add Vehicle',
                    onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
                  ),
                ],
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;
                final childAspectRatio = crossAxisCount == 2 ? 1.2 : 0.85;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vehicles.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        return KeyedSubtree(
                          key: ValueKey('vehicle-${v.id}'),
                          child: CustomerGarageVehicleCard(
                            vehicle: v,
                            onDelete: () => confirmDeleteCustomerVehicle(context, ref, v),
                            onEdit: () => showCustomerAddVehicleDialog(context, ref, uid, vehicle: v),
                            onDetails: () => showCustomerVehicleDetailsModal(context, ref, v),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    CustomerGarageAddButton(
                      label: 'Add Vehicle',
                      onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (_, _) => Text('Error loading garage', style: TextStyle(color: BoostDriveTheme.textDim)),
        );
  }
}

class _GarageOrdersBlock extends ConsumerWidget {
  const _GarageOrdersBlock({required this.uid});

  final String uid;

  static double _progressForStatus(String status) {
    var progress = 0.2;
    if (status == 'at_pickup' || status == 'picking_up') progress = 0.4;
    if (status == 'in_transit') progress = 0.7;
    if (status == 'delivered') progress = 1.0;
    return progress;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(activeDeliveriesProvider(uid)).when(
          data: (orders) {
            if (orders.isEmpty) {
              return Text('No active orders.', style: TextStyle(color: BoostDriveTheme.textDim));
            }
            return Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  KeyedSubtree(
                    key: ValueKey('order-${orders[i].id}'),
                    child: _GarageOrderTile(order: orders[i], progress: _progressForStatus(orders[i].status)),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (_, _) => Text('Error loading orders', style: TextStyle(color: BoostDriveTheme.textDim)),
        );
  }
}

class _GarageOrderTile extends StatelessWidget {
  const _GarageOrderTile({required this.order, required this.progress});

  final DeliveryOrder order;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final itemsMap = Map<String, dynamic>.from(order.items);
    return CustomerGarageOrderCard(
      title: itemsMap['title']?.toString() ?? 'Product Delivery',
      id: '#${order.id.substring(0, 8).toUpperCase()}',
      status: order.status.replaceAll('_', ' ').toUpperCase(),
      description: itemsMap['description']?.toString() ?? 'See details for more info',
      eta: order.eta.isNotEmpty ? order.eta : 'Calculating ETA...',
      progress: progress,
    );
  }
}

class _GarageServiceHistoryBlock extends ConsumerWidget {
  const _GarageServiceHistoryBlock({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userServiceHistoryProvider(uid)).when(
          data: (history) {
            if (history.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No service records found.', style: TextStyle(color: BoostDriveTheme.textDim)),
                  const SizedBox(height: 16),
                  ref.watch(userVehiclesProvider(uid)).when(
                    data: (vehicles) => vehicles.isNotEmpty
                        ? CustomerGarageAddButton(
                            label: 'Log First Service',
                            onPressed: () => showCustomerLogServiceDialog(context, ref, uid, vehicles.first.id),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              );
            }
            return Column(
              children: [
                for (final item in history)
                  KeyedSubtree(
                    key: ValueKey('history-${item.id}'),
                    child: CustomerGarageHistoryItem(
                      item: item,
                      onDelete: () => confirmDeleteCustomerServiceRecord(context, ref, uid, item),
                      onEdit: () => showCustomerLogServiceDialog(context, ref, uid, item.vehicleId, record: item),
                      onDetails: () => showCustomerServiceRecordDetailsDialog(context, item),
                      onViewReceipts: item.receiptUrls.isNotEmpty
                          ? () => showCustomerViewReceiptsDialog(context, item.receiptUrls)
                          : null,
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(
                'Service history is temporarily offline. Check connection and retry.',
                style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => ref.invalidate(userServiceHistoryProvider(uid)),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        );
  }
}
