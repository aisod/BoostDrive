import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_core/boostdrive_core.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';

/// Mobile Garage tab — Kinetic Precision layout (Stitch mobile_garage_list).
class GaragePage extends ConsumerWidget {
  const GaragePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final palette = DashboardPalette.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: palette.background,
        body: Center(child: Text('Please log in', style: TextStyle(color: palette.body))),
      );
    }

    final uid = user.id;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: MobileCustomerUi.topAppBar(
        context: context,
        title: 'GARAGE',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
        backgroundColor: palette.primaryContainer,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add, size: 32),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: CustomerGarageUi.marginMobile),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _GarageHeader(uid: uid),
              const SizedBox(height: 24),
              _GarageVehiclesBlock(uid: uid),
              const SizedBox(height: 40),
              const CustomerGarageSectionHeader(title: 'Active Orders', icon: Icons.local_shipping),
              const SizedBox(height: 16),
              _GarageOrdersBlock(uid: uid),
              const SizedBox(height: 40),
              const CustomerGarageSectionHeader(title: 'Service History', icon: Icons.history),
              const SizedBox(height: 16),
              _GarageServiceHistoryBlock(uid: uid),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _GarageHeader extends ConsumerWidget {
  const _GarageHeader({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DashboardPalette.of(context);
    return ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) => CustomerGarageUi.garagePageHeader(
                palette: palette,
                vehicleCount: vehicles.length,
              ),
          loading: () => CustomerGarageUi.garagePageHeader(palette: palette, vehicleCount: 0),
          error: (_, _) => CustomerGarageUi.garagePageHeader(palette: palette, vehicleCount: 0),
        );
  }
}

class _GarageVehiclesBlock extends ConsumerWidget {
  const _GarageVehiclesBlock({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = DashboardPalette.of(context);

    return ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No vehicles found in your garage.',
                    style: DashboardTypography.bodyMd(palette),
                  ),
                  const SizedBox(height: 16),
                  CustomerGarageAddButton(
                    label: 'Add Vehicle',
                    onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
                  ),
                ],
              );
            }

            final featured = vehicles.first;
            final others = vehicles.length > 1 ? vehicles.sublist(1) : <Vehicle>[];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomerGarageUi.featuredVehicleCard(
                  palette: palette,
                  vehicle: featured,
                  onTap: () => showCustomerVehicleDetailsModal(context, ref, featured),
                ),
                if (others.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'OTHER VEHICLES',
                    style: DashboardTypography.sectionLabel(palette),
                  ),
                  const SizedBox(height: 8),
                  for (final v in others)
                    CustomerGarageVehicleCard(
                      vehicle: v,
                      onDelete: () => confirmDeleteCustomerVehicle(context, ref, v),
                      onEdit: () => showCustomerAddVehicleDialog(context, ref, uid, vehicle: v),
                      onDetails: () => showCustomerVehicleDetailsModal(context, ref, v),
                    ),
                ],
              ],
            );
          },
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text('Error loading garage', style: TextStyle(color: palette.muted)),
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
    final palette = DashboardPalette.of(context);

    return ref.watch(activeDeliveriesProvider(uid)).when(
          data: (orders) {
            if (orders.isEmpty) {
              return Text('No active orders.', style: DashboardTypography.bodyMd(palette));
            }
            return Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  KeyedSubtree(
                    key: ValueKey('order-${orders[i].id}'),
                    child: _GarageOrderTile(order: orders[i], progress: _progressForStatus(orders[i].status)),
                  ),
                ],
              ],
            );
          },
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (_, _) => Text('Error loading orders', style: TextStyle(color: palette.muted)),
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
    final palette = DashboardPalette.of(context);

    return ref.watch(userServiceHistoryProvider(uid)).when(
          data: (history) {
            if (history.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No service records found.', style: DashboardTypography.bodyMd(palette)),
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
              Icon(Icons.error_outline, color: palette.error),
              const SizedBox(height: 8),
              Text(
                'Service history is temporarily offline. Check connection and retry.',
                style: TextStyle(color: palette.error, fontSize: 12, fontWeight: FontWeight.w700),
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
