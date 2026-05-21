import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:boostdrive_ui/boostdrive_ui.dart';
import 'package:boostdrive_auth/boostdrive_auth.dart';
import 'package:boostdrive_services/boostdrive_services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:boost_drive_web/dashboard_shell.dart';
import 'user_support_view.dart';
import 'boostdrive_banner.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return DashboardAppShell(
      activeTab: DashboardNavTab.dashboard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Consumer(
            builder: (context, ref, _) {
              final alertsAsync = ref.watch(activeDashboardAlertsStreamProvider(user.id));
              return alertsAsync.when(
                data: (alerts) {
                  if (alerts.isEmpty) return const SizedBox.shrink();
                  return BoostDriveBanner(
                    alert: alerts.first,
                    onAction: (ticketId) {
                      ref.read(pendingSupportTicketIdProvider.notifier).state = ticketId;
                    },
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          DashboardPageContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeSection(context, ref, user.id),
                const SizedBox(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildMainContent(context, ref, user.id)),
                          const SizedBox(width: 24),
                          Expanded(flex: 1, child: _buildSideContent(context, ref, user.id)),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildMainContent(context, ref, user.id),
                        const SizedBox(height: 32),
                        _buildSideContent(context, ref, user.id),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, WidgetRef ref, String uid) {
    final vehicles = ref.watch(userVehiclesProvider(uid)).valueOrNull ?? [];
    final orders = ref.watch(activeDeliveriesProvider(uid)).valueOrNull ?? [];

    return ref.watch(userProfileProvider(uid)).when(
      data: (profile) {
        if (profile == null) return const SizedBox();
        return DashboardWelcomeHeader(
          title: 'Welcome back, ${profile.fullName}',
          subtitle:
              'Manage your ${vehicles.length} registered ${vehicles.length == 1 ? 'vehicle' : 'vehicles'} and track ${orders.length} active ${orders.length == 1 ? 'order' : 'orders'}.',
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Text('Error loading profile'),
    );
  }

  Widget _buildMainContent(BuildContext context, WidgetRef ref, String uid) {
    final palette = DashboardPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          title: 'Live Tracking',
          icon: Icons.location_on_outlined,
          trailing: TextButton.icon(
            onPressed: () => _openFullscreenMap(context, ref, uid),
            icon: Icon(Icons.open_in_full, color: palette.primary, size: 18),
            label: Text(
              'FULLSCREEN',
              style: GoogleFonts.montserrat(
                color: palette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        DashboardCard(
          padding: EdgeInsets.zero,
          elevated: true,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: palette.cardBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Live Tracking',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: palette.primary,
                        ),
                      ),
                    ),
                    const DashboardStatusChip(label: 'In Progress'),
                  ],
                ),
              ),
              SizedBox(
                height: 260,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: ref.watch(activeDeliveriesProvider(uid)).when(
                    data: (deliveries) {
                      final active = deliveries
                          .where((d) => d.status != 'delivered' && d.status != 'cancelled')
                          .toList();
                      final markers = active.map((d) {
                        final lat = d.dropoffLocation['lat'] as double? ?? -22.5609;
                        final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
                        return Marker(markerId: MarkerId(d.id), position: LatLng(lat, lng));
                      }).toSet();
                      return GoogleMap(
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(-22.5609, 17.0658),
                          zoom: 6,
                        ),
                        markers: markers,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(child: CustomerGarageSectionHeader(title: 'My Garage', icon: Icons.directions_car)),
            CustomerGarageAddButton(
              label: 'Add Vehicle',
              onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ref.watch(userVehiclesProvider(uid)).when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No vehicles found in your garage.', style: TextStyle(color: palette.body)),
                    const SizedBox(height: 12),
                    CustomerGarageAddButton(
                      label: 'Add Vehicle',
                      onPressed: () => showCustomerAddVehicleDialog(context, ref, uid),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                ...vehicles.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: CustomerGarageVehicleCard(
                      vehicle: v,
                      onDelete: () => confirmDeleteCustomerVehicle(context, ref, v),
                      onEdit: () => showCustomerAddVehicleDialog(context, ref, uid, vehicle: v),
                      onDetails: () => showCustomerVehicleDetailsModal(context, ref, v),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading garage'),
        ),
        const SizedBox(height: 32),
        DashboardSectionHeader(title: 'Active Orders', icon: Icons.local_shipping_outlined),
        const SizedBox(height: 16),
        ref.watch(activeDeliveriesProvider(uid)).when(
          data: (orders) {
            if (orders.isEmpty) {
              return Text('No active orders.', style: TextStyle(color: palette.body));
            }
            return Column(
              children: orders.map((o) {
                final itemsMap = Map<String, dynamic>.from(o.items);
                double progress = 0.2;
                if (o.status == 'at_pickup' || o.status == 'picking_up') progress = 0.4;
                if (o.status == 'in_transit') progress = 0.7;
                if (o.status == 'delivered') progress = 1.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CustomerGarageOrderCard(
                    title: itemsMap['title']?.toString() ?? 'Product Delivery',
                    id: '#${o.id.substring(0, 8).toUpperCase()}',
                    status: o.status.replaceAll('_', ' ').toUpperCase(),
                    description: itemsMap['description']?.toString() ?? 'See details for more info',
                    eta: o.eta.isNotEmpty ? o.eta : 'Calculating ETA...',
                    progress: progress,
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Error loading orders'),
        ),
        const SizedBox(height: 48),
        UserSupportView(userId: uid, userType: 'customer'),
      ],
    );
  }

  Widget _buildSideContent(BuildContext context, WidgetRef ref, String uid) {
    final palette = DashboardPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(title: 'Service History', icon: Icons.history),
        const SizedBox(height: 16),
        ref.watch(userServiceHistoryProvider(uid)).when(
          data: (history) {
            if (history.isEmpty) {
              return DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No service records found.', style: TextStyle(color: palette.body)),
                    const SizedBox(height: 12),
                    ref.watch(userVehiclesProvider(uid)).when(
                      data: (vehicles) => vehicles.isNotEmpty
                          ? CustomerGarageAddButton(
                              label: 'Log First Service',
                              onPressed: () =>
                                  showCustomerLogServiceDialog(context, ref, uid, vehicles.first.id),
                            )
                          : const SizedBox(),
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: history
                  .map(
                    (item) => CustomerGarageHistoryItem(
                      item: item,
                      onDelete: () => confirmDeleteCustomerServiceRecord(context, ref, uid, item),
                      onEdit: () => showCustomerLogServiceDialog(context, ref, uid, item.vehicleId, record: item),
                      onDetails: () => showCustomerServiceRecordDetailsDialog(context, item),
                      onViewReceipts: item.receiptUrls.isNotEmpty
                          ? () => showCustomerViewReceiptsDialog(context, item.receiptUrls)
                          : null,
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => DashboardCard(
            child: Column(
              children: [
                Icon(Icons.error_outline, color: palette.error),
                const SizedBox(height: 8),
                Text(
                  'Service history is temporarily offline.',
                  style: GoogleFonts.montserrat(color: palette.error, fontSize: 12, fontWeight: FontWeight.w600),
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
          ),
        ),
      ],
    );
  }

  void _openFullscreenMap(BuildContext context, WidgetRef ref, String uid) {
    final palette = DashboardPalette.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.navBar,
            foregroundColor: Colors.white,
            title: const Text('Live Dispatch Map'),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: ref.watch(activeDeliveriesProvider(uid)).when(
            data: (deliveries) {
              final active = deliveries
                  .where((d) => d.status != 'delivered' && d.status != 'cancelled')
                  .toList();
              final markers = active.map((d) {
                final lat = d.dropoffLocation['lat'] as double? ?? -22.5609;
                final lng = d.dropoffLocation['lng'] as double? ?? 17.0658;
                return Marker(
                  markerId: MarkerId(d.id),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(title: 'Order ${d.id.substring(0, 4)}'),
                );
              }).toSet();
              return GoogleMap(
                initialCameraPosition: const CameraPosition(target: LatLng(-22.5609, 17.0658), zoom: 6),
                markers: markers,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ),
    );
  }
}
